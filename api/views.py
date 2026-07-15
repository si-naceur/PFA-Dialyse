from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.contrib.auth.hashers import make_password
from django.db.models import Q

import json
import re
import requests
import string
import secrets
import logging

from accounts.models import User, Role
from machines.models import Machine
from seances.models import Seance
from monitoring.models import VitalReading, Alerte, ConversationLog


QWEN_URL     = "http://127.0.0.1:8001/conseil"   # Qwen VL-3B — images uniquement
OLLAMA_URL_G = "http://localhost:11434/api/chat"  # Ollama — tous les agents texte
OLLAMA_MOD_G = "qwen2.5:3b"


def call_qwen(message: str, niveau: str = "INFO", timeout: int = 120) -> str:
    """
    Appelle Ollama qwen2.5:3b pour tous les agents textuels.
    Garde la signature originale pour compatibilité avec les agents 1-5.
    """
    try:
        resp = requests.post(
            OLLAMA_URL_G,
            json={
                "model":   OLLAMA_MOD_G,
                "messages": [{"role": "user", "content": message}],
                "stream":  False,
                "options": {"temperature": 0, "num_predict": 300},
            },
            timeout=timeout,
        )
        resp.raise_for_status()
        return resp.json().get("message", {}).get("content", "").strip()
    except Exception as e:
        logging.error(f"[Ollama call_qwen] error: {e}")
        return ""



# =========================
# RECEIVE MEASUREMENTS
# =========================
@csrf_exempt
def receive_measurements(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)

    try:
        data = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "invalid json"}, status=400)

    machine_id = data.get("machine_id")
    if not machine_id:
        return JsonResponse({"error": "missing machine_id"}, status=400)

    try:
        machine = Machine.objects.get(machine_id=machine_id)
    except Machine.DoesNotExist:
        return JsonResponse({"error": "machine unknown"}, status=404)

    seance = Seance.objects.filter(machine=machine, status="en cours").first()
    if not seance:
        return JsonResponse({"error": "no active seance"}, status=404)

    def to_float(value):
        try:
            return float(value)
        except (TypeError, ValueError):
            return None

    reading = VitalReading.objects.create(
        seance=seance,
        timestamp=timezone.now(),
        Debit_sang=to_float(data.get("Qb")),
        PTM=to_float(data.get("PTM")),
        PA=to_float(data.get("PA")),
        PV=to_float(data.get("PV")),
        Taux_UF=to_float(data.get("UF_rate")),
        Volume_UF=to_float(data.get("UF_volume")),
        Heparine=to_float(data.get("Heparin")),
    )

    return JsonResponse({
        "status": "saved",
        "reading_id": str(reading.id),
        "message": "reading stored — Agent 1 (IA) will decide alert"
    })



def _seuils_depuis_seance(seance) -> dict:
    """Lit les seuils configurés dans la séance."""
    return {
        "Debit_sang": {
            "label": "Débit sanguin", "unite": "mL/min",
            "min": seance.blood_flow_min, "max": seance.blood_flow_max,
            "crit_min": seance.blood_flow_critical_low, "crit_max": seance.blood_flow_critical_high,
        },
        "PA": {
            "label": "Pression artérielle", "unite": "mmHg",
            "min": seance.arterial_pressure_min, "max": seance.arterial_pressure_max,
            "crit_min": seance.arterial_pressure_critical_low, "crit_max": seance.arterial_pressure_critical_high,
        },
        "PV": {
            "label": "Pression veineuse", "unite": "mmHg",
            "min": seance.venous_pressure_min, "max": seance.venous_pressure_max,
            "crit_min": seance.venous_pressure_critical_low, "crit_max": seance.venous_pressure_critical_high,
        },
        "PTM": {
            "label": "Pression transmembranaire", "unite": "mmHg",
            "min": seance.tmp_min, "max": seance.tmp_max,
            "crit_min": seance.tmp_critical_low, "crit_max": seance.tmp_critical_high,
        },
        "Taux_UF": {
            "label": "Taux UF", "unite": "mL/h",
            "min": seance.uf_rate_min, "max": seance.uf_rate_max,
            "crit_min": 0, "crit_max": seance.uf_rate_critical_high,
        },
        "Volume_UF": {
            "label": "Volume UF", "unite": "mL",
            "min": seance.uf_volume_min, "max": seance.uf_volume_max,
            "crit_min": 0, "crit_max": seance.uf_volume_critical_high,
        },
        "Heparine": {
            "label": "Héparine", "unite": "UI/h",
            "min": seance.heparin_min, "max": seance.heparin_max,
            "crit_min": 0, "crit_max": seance.heparin_critical_high,
        },
    }


def _extraire_seuils_prompt(doctor_prompt: str, seuils_machine: dict) -> dict:
    """
    Utilise l'IA pour extraire les seuils mentionnés dans le prompt médecin.
    L'IA ne décide PAS des alertes — elle traduit juste le texte en nombres.
    """
    if not doctor_prompt or not doctor_prompt.strip():
        return {}

    seuils_actuels = "\n".join([
        f"- {v['label']} : min={v['min']} max={v['max']} crit_min={v['crit_min']} crit_max={v['crit_max']} {v['unite']}"
        for v in seuils_machine.values()
    ])

    prompt = f"""Tu es un parseur médical. Extrais UNIQUEMENT les valeurs numériques de seuils mentionnées dans ce texte.

Texte du médecin : "{doctor_prompt}"

Seuils actuels de la machine (pour référence) :
{seuils_actuels}

Retourne UNIQUEMENT un JSON avec les seuils modifiés par le médecin.
Utilise exactement ces clés : Debit_sang, PA, PV, PTM, Taux_UF, Volume_UF, Heparine
Pour chaque champ modifié, inclus uniquement les sous-clés mentionnées parmi : min, max, crit_min, crit_max

Exemple — si le texte dit "alerter si PA < 80" :
{{"PA": {{"crit_min": 80}}}}

Si rien n'est mentionné pour un champ, ne l'inclus pas.
Si aucun seuil n'est mentionné du tout, retourne {{}}

Réponds UNIQUEMENT avec le JSON, sans texte autour."""

    try:
        response = requests.post(
            OLLAMA_URL_ALERTE,
            json={"model": OLLAMA_MOD_ALERTE, "prompt": prompt, "stream": False},
            timeout=30,
        )
        raw   = response.json().get("response", "")
        raw   = re.sub(r"```(?:json)?|```", "", raw).strip()
        match = re.search(r"\{.*\}", raw, re.DOTALL)
        if match:
            seuils_custom = json.loads(match.group())
            if seuils_custom:
                logging.info(f"[PROMPT MÉDECIN] Seuils extraits : {seuils_custom}")
            return seuils_custom
    except Exception as e:
        logging.warning(f"[PROMPT MÉDECIN] Erreur extraction : {e}")
    return {}


def _fusionner_seuils(seuils_machine: dict, seuils_custom: dict) -> dict:
    """Applique les seuils du prompt médecin PAR-DESSUS les seuils machine."""
    seuils_finaux = {}
    for champ, s in seuils_machine.items():
        seuil = dict(s)
        if champ in seuils_custom:
            for sous_cle in ("min", "max", "crit_min", "crit_max"):
                if sous_cle in seuils_custom[champ]:
                    seuil[sous_cle] = seuils_custom[champ][sous_cle]
        seuils_finaux[champ] = seuil
    return seuils_finaux


def _detecter_alertes(reading, seuils: dict) -> list:
    """
    Détection 100% numérique — pas d'IA impliquée.
    Retourne une liste d'alertes avec danger_level HIGH ou MEDIUM.
    """
    alertes = []
    for champ, s in seuils.items():
        valeur = getattr(reading, champ, None)
        if valeur is None:
            continue
        try:
            valeur = float(valeur)
        except (TypeError, ValueError):
            continue

        label    = s["label"]
        unite    = s["unite"]
        crit_min = s.get("crit_min")
        crit_max = s.get("crit_max")
        norm_min = s.get("min")
        norm_max = s.get("max")
        niveau   = None
        message  = None
        action   = None

        if crit_min is not None and valeur < crit_min:
            niveau  = "HIGH"
            message = f"🔴 CRITIQUE — {label} très bas : {valeur} {unite} (seuil critique : {crit_min} {unite})"
            action  = f"Vérifier immédiatement la ligne. Alerter le médecin si {label} reste sous {crit_min} {unite}."
        elif crit_max is not None and valeur > crit_max:
            niveau  = "HIGH"
            message = f"🔴 CRITIQUE — {label} très élevé : {valeur} {unite} (seuil critique : {crit_max} {unite})"
            action  = f"Réduire le débit ou ajuster les paramètres. Alerter le médecin si {label} dépasse {crit_max} {unite}."
        elif norm_min is not None and valeur < norm_min:
            niveau  = "MEDIUM"
            message = f"🟡 ATTENTION — {label} bas : {valeur} {unite} (normal min : {norm_min} {unite})"
            action  = f"Surveiller {label}. Vérifier les connexions et paramètres de la machine."
        elif norm_max is not None and valeur > norm_max:
            niveau  = "MEDIUM"
            message = f"🟡 ATTENTION — {label} élevé : {valeur} {unite} (normal max : {norm_max} {unite})"
            action  = f"Surveiller {label}. Envisager un ajustement des paramètres de dialyse."

        if niveau:
            alertes.append({
                "alert_type":         label,
                "message":            message,
                "danger_level":       niveau,
                "recommended_action": action,
            })
    return alertes

@csrf_exempt
def agent_alerte(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)

    try:
        body = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "invalid json"}, status=400)

    reading_id = body.get("reading_id")
    machine_id = body.get("machine_id", "A1")
   
    if not reading_id:
        return JsonResponse({"error": "missing reading_id"}, status=400)

    try:
        reading = VitalReading.objects.get(id=reading_id)
    except VitalReading.DoesNotExist:
        return JsonResponse({"error": "reading not found"}, status=404)

    seance = reading.seance
    # antecedant = seance.patient.antecedents_medicaux()
    # ── Étape 1 : seuils machine ──────────────────────────────────────────────
    seuils_machine = _seuils_depuis_seance(seance)

    # ── Étape 2 : seuils prompt médecin (si présent) ──────────────────────────
    seuils_custom = {}
    if getattr(seance, "doctor_prompt", None) and seance.doctor_prompt.strip():
        seuils_custom = _extraire_seuils_prompt(seance.doctor_prompt, seuils_machine)
    

    # ── Étape 3 : fusion (prompt médecin prioritaire) ─────────────────────────
    seuils_finaux = _fusionner_seuils(seuils_machine, seuils_custom)
    # seuils_finaux= _fusionner_seuils(seuils_finaux,antecedant)
    # ── Étape 4 : détection numérique ─────────────────────────────────────────
    alertes = _detecter_alertes(reading, seuils_finaux)
    logging.info(f"[ALERTE] {len(alertes)} alerte(s) | prompt médecin : {'OUI' if seuils_custom else 'NON'}")

    if not alertes:
        return JsonResponse({
            "status":     "no_alert",
            "niveau":     "AUCUNE",
            "reading_id": str(reading.id),
            "machine_id": machine_id,
            "seance_id":  str(seance.id),
            "raison":     "Toutes les valeurs sont dans les limites normales.",
        })

    # ── Étape 5 : sauvegarde des alertes en base ──────────────────────────────
    alertes_sauvegardees = []
    for a in alertes:
        niveau_db = "ROUGE" if a["danger_level"] == "HIGH" else "JAUNE"
        alerte_obj = Alerte.objects.create(
            reading=reading,
            message=a["message"],
            niveau=niveau_db,
            conseil=a.get("recommended_action"),
        )
        alertes_sauvegardees.append({
            "alerte_id":   str(alerte_obj.id),
            "niveau":      niveau_db,
            "danger_level": a["danger_level"],
            "alert_type":  a["alert_type"],
            "message":     a["message"],
            "action":      a.get("recommended_action"),
        })

    # Résumé pour la réponse
    has_high = any(a["danger_level"] == "HIGH" for a in alertes)
    return JsonResponse({
        "status":     "alertes_created",
        "count":      len(alertes_sauvegardees),
        "has_high":   has_high,
        "niveau":     "ROUGE" if has_high else "JAUNE",
        "reading_id": str(reading.id),
        "machine_id": machine_id,
        "seance_id":  str(seance.id),
        "alertes":    alertes_sauvegardees,
    })



@csrf_exempt
def agent_conseil(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)

    try:
        body = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "invalid json"}, status=400)

    alerte_id_raw = body.get("alerte_id")
    message = body.get("message", "")
    niveau = body.get("niveau", "JAUNE")
    parametre = body.get("parametre", "")
    valeur = body.get("valeur", "")

    if not message:
        return JsonResponse({"error": "missing message", "body": body}, status=400)

    try:
        alerte_id = int(alerte_id_raw)
    except Exception:
        alerte_id = None

    prompt = f"""
Alerte dialyse {niveau}.
Paramètre: {parametre}
Valeur: {valeur}
Message: {message}

Donne 3 actions infirmier immédiates, courtes et pratiques.
Réponse en français.
Format:
1. ...
2. ...
3. ...
"""

    fallback = (
        "1. Vérifier immédiatement l'état du patient. "
        "2. Contrôler les paramètres de la machine. "
        "3. Prévenir le médecin si l'anomalie persiste."
    )

    try:
        conseil_text = call_qwen(prompt, niveau=niveau, timeout=30).strip()
        if not conseil_text:
            conseil_text = fallback
    except Exception:
        conseil_text = fallback

    saved = False
    if alerte_id:
        try:
            alerte = Alerte.objects.get(id=alerte_id)
            alerte.conseil = conseil_text
            alerte.save(update_fields=["conseil"])
            saved = True
        except Alerte.DoesNotExist:
            pass

    return JsonResponse({
        "status": "ok",
        "alerte_id": alerte_id,
        "alerte_id_raw": alerte_id_raw,
        "saved": saved,
        "conseil": conseil_text,
        "urgence": niveau == "ROUGE",
    })



# =========================
# AGENT 3 — PREDICTION
# =========================
@csrf_exempt
def agent_prediction(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)

    try:
        body = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "invalid json"}, status=400)

    machine_id = body.get("machine_id", "A1")

    try:
        machine = Machine.objects.get(machine_id=machine_id)
    except Machine.DoesNotExist:
        return JsonResponse({"error": "machine unknown"}, status=404)

    seance = Seance.objects.filter(machine=machine, status="en cours").first()
    if not seance:
        return JsonResponse({
            "risque_critique": False,
            "tendance": "stable",
            "machine_id": machine_id,
            "raison": "Aucune séance active."
        })

    readings = list(
        VitalReading.objects.filter(seance=seance)
        .order_by('-timestamp')[:5]
        .values('Debit_sang', 'PTM', 'PA', 'PV', 'Taux_UF', 'Volume_UF', 'Heparine')
    )

    if not readings:
        return JsonResponse({
            "risque_critique": False,
            "tendance": "stable",
            "machine_id": machine_id,
            "raison": "Pas de données."
        })

    prompt = (
        f"Dialyse {machine_id}. {len(readings)} mesures: {json.dumps(readings)}. "
        f'Tendance? JSON: {{"risque_critique":bool,"tendance":"hausse|baisse|stable","parametre_critique":"nom|null","prediction":"court","action_infirmier":"court"}}'
    )

    try:
        raw   = call_qwen(prompt, niveau="PREDICTION", timeout=60)
        match = re.search(r"\{[\s\S]*\}", raw)

        if not match:
            raise ValueError("No JSON")
        result = json.loads(match.group())
        result["machine_id"] = machine_id
        return JsonResponse(result)

    except Exception as e:
        return JsonResponse({"error": str(e), "risque_critique": False}, status=500)


# =========================
# AGENT 5 — RESUME SEANCE
# =========================
@csrf_exempt
def agent_resume_seance(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)

    try:
        body = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "invalid json"}, status=400)

    seance_id = body.get("seance_id")
    if not seance_id:
        return JsonResponse({"error": "missing seance_id"}, status=400)

    try:
        seance = Seance.objects.get(id=seance_id)
    except Seance.DoesNotExist:
        return JsonResponse({"error": "seance not found"}, status=404)

    readings = LiveMeasurement.objects.filter(seance=seance).order_by("timestamp")
    alertes = Alert.objects.filter(seance=seance).order_by("timestamp")

    if not readings.exists():
        return JsonResponse({"error": "no readings for this seance"}, status=404)

    def safe_avg(values):
        vals = [v for v in values if v is not None]
        return round(sum(vals) / len(vals), 1) if vals else None

    def safe_max(values):
        vals = [v for v in values if v is not None]
        return max(vals) if vals else None

    def safe_min(values):
        vals = [v for v in values if v is not None]
        return min(vals) if vals else None

    stats = {
        "Qb": {
            "moy": safe_avg([r.Debit_sang for r in readings]),
            "max": safe_max([r.Debit_sang for r in readings]),
            "min": safe_min([r.Debit_sang for r in readings]),
        },
        "PTM": {
            "moy": safe_avg([r.PTM for r in readings]),
            "max": safe_max([r.PTM for r in readings]),
            "min": safe_min([r.PTM for r in readings]),
        },
        "PA": {
            "moy": safe_avg([r.PA for r in readings]),
            "max": safe_max([r.PA for r in readings]),
            "min": safe_min([r.PA for r in readings]),
        },
        "PV": {
            "moy": safe_avg([r.PV for r in readings]),
            "max": safe_max([r.PV for r in readings]),
            "min": safe_min([r.PV for r in readings]),
        },
        "UF_volume_final": readings.last().Volume_UF,
    }

    alertes_list = [
        {
            "niveau": a.niveau,
            "message": a.message,
            "timestamp": a.timestamp.strftime("%H:%M:%S"),
        }
        for a in alertes
    ]

    duree_minutes = getattr(seance, "duration", None)

    prompt = f"""You are a medical assistant. Generate a concise end-of-session summary.

Session info:
- Patient: {getattr(seance, 'patient', 'Unknown')}
- Duration: {duree_minutes} minutes
- Total readings: {readings.count()}
- Total alerts: {alertes.count()}

Average values:
{json.dumps(stats, indent=2)}

Alerts:
{json.dumps(alertes_list, indent=2)}

Reply ONLY with JSON:
{{
  "resume_court": "2-sentence summary",
  "qualite_seance": "bonne/moyenne/difficile",
  "points_attention": ["point1", "point2"],
  "resume_complet": "full paragraph in French"
}}"""

    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={"model": "qwen2.5:1.5b","message": prompt, "niveau": "RESUME"},
            timeout=300
        )
        data = response.json()
        raw = data.get("conseil", "{}")

        match = re.search(r'\{.*\}', raw, re.DOTALL)
        if match:
            try:
                result = json.loads(match.group())
            except Exception:
                result = {
                     "resume_court": "Résumé IA indisponible.",
                     "qualite_seance": "moyenne",
                     "points_attention": [],
                     "resume_complet": raw
                 }
        else:
                result = {
                    "resume_court": "Résumé IA indisponible.",
                    "qualite_seance": "moyenne",
                    "points_attention": [],
                    "resume_complet": raw
                }

    except Exception as e:
        print("Erreur IA agent_resume_seance:", e)
        result = {
            "resume_court": "Résumé automatique indisponible.",
            "qualite_seance": "moyenne",
            "points_attention": [],
            "resume_complet": "Le serveur IA n'a pas répondu à temps."
        }
    # ── Données pour les graphiques ───────────────────────────
    chart_data = []
    if readings.exists():
        t0 = readings.first().timestamp
        for r in readings:
            delta = int((r.timestamp - t0).total_seconds() / 60)
            chart_data.append({
                "time":      delta,
                "pa":        r.PA,
                "ptm":       r.PTM,
                "pv":        r.PV,
                "qb":        r.Debit_sang,
                "uf_volume": r.Volume_UF,
                "heparin":   r.Heparine,
            })

    # ── Mesures pré / post ────────────────────────────────────
    pre  = PreSessionMeasurements.objects.filter(seance=seance).first()
    post = PostSessionMeasurements.objects.filter(seance=seance).first()
    # ── Rendu HTML du rapport ─────────────────────────────────
    html_content = render_to_string("rapport_seance.html", {
        "seance":        seance,
        "patient":       seance.patient,
        "machine":       seance.machine,
        "pre":           pre,
        "post":          post,
        "last_reading":  readings.last(),
        "chart_data":    json.dumps(chart_data),
        "alerts_json":   json.dumps(alertes_list),
        "qualite":       result.get("qualite_seance", "moyenne"),
        "nb_alertes":    alertes.count(),
        "nb_critiques":  sum(1 for a in alertes_list if a["niveau"] == "HIGH"),
        "resume_court":  result.get("resume_court", ""),
        "resume_complet": result.get("resume_complet", ""),
        "points_attention": result.get("points_attention", []),
        "is_rapport":    True,
    })

    # ── Nom du fichier & sauvegarde en base ───────────────────
    import unicodedata, re as _re
    def slugify(text):
        text = unicodedata.normalize("NFD", text).encode("ascii", "ignore").decode()
        return _re.sub(r"[^a-zA-Z0-9]", "", text.title())
    

    nom_fichier = f"{seance_id}.html"

    RapportSeance.objects.update_or_create(
        seance=seance,
        defaults={
            "nom_fichier":    nom_fichier,
            "contenu_html":   html_content,
            "qualite_seance": result.get("qualite_seance", "moyenne"),
            
        },
    )
    

    # ── Réponse JSON pour n8n ─────────────────────────────────
    return JsonResponse({
        "status":     "ok",
        "seance_id":  seance_id,
        "stats":      stats,
        "nb_alertes": alertes.count(),
        "duree_minutes": duree_minutes,
        "qualite_seance": result.get("qualite_seance", "moyenne"),
        "resume_court": result.get("resume_court", ""), 
        
        **result
    })
@csrf_exempt
def agent_email_seance(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)
    try:
        body = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "invalid json"}, status=400)

    seance_id = body.get("seance_id")
    seance=Seance.objects.filter(id=seance_id).first()
    patient= seance.patient
    first_name = patient.first_name if patient.first_name else "Inconnu"
    last_name = patient.last_name if patient.last_name else "Inconnu"
    date_str = seance.session_date.strftime("%d/%m/%Y") if seance.session_date else "Date inconnue"
    duree_minutes = seance.duration if seance and seance.duration else "Inconnue"
    result = body.get("result", {})
    alertes_list = body.get("alertes_list", [])
    machine_id = seance.machine.machine_id if seance and seance.machine else "Inconnue"
    
    # ── Prompt pour l'email ───────────────────────────────────
    email_prompt = f"""Tu es un système de surveillance médicale automatisé. 
Rédige un email de notification médical strict, factuel et concis en français.

DONNÉES DE LA SÉANCE :
- Patient       : {first_name} {last_name}
- Date          : {date_str}
- Durée         : {duree_minutes} heures
- Machine       : {machine_id}
- Qualité       : {result.get('qualite_seance', 'moyenne')}
- Alertes       : {len(alertes_list)} au total / {sum(1 for a in alertes_list if a['niveau'] == 'HIGH')} critique(s)
- Résumé        : {result.get('resume_complet', '')}
- Points clés   : {', '.join(result.get('points_attention', [])) or 'Aucun'}
- Rapport       : http://192.168.100.7:8000/patients/{seance_id}/detail/

RÈGLES STRICTES :
1. Commence par "Bonjour Dr,"
2. Présente le patient et la date en une phrase
3. Décris les faits cliniques en 2-3 phrases maximum — chiffres et faits uniquement
4. Liste les points d'attention sous forme de puces (•)
5. Inclus le lien rapport sur une ligne séparée
6. Termine par : "Cordialement, Système de surveillance hémodialyse"
7. INTERDIT : recommandations de traitement, formules de politesse superflues, remerciements, propositions de services, opinions, suppositions
8. Ton : médical, neutre, factuel — comme un compte-rendu clinique automatisé

Réponds UNIQUEMENT avec le texte de l'email. Aucune balise, aucun JSON, aucun commentaire."""
    try:
        email_response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "qwen2.5:1.5b",
                "prompt": email_prompt,
                "stream": False
            },
            timeout=120
        )
        email_data = email_response.json()
        email_body = email_data.get("response", "").strip()
        if not email_body:
            raise ValueError("Réponse vide")
    except Exception as e:
        print("Erreur génération email IA:", e)
    # Fallback manuel si l'IA ne répond pas
        email_body = f"""Bonjour Dr,

    La séance du patient {first_name} {last_name} en date du {date_str} s'est déroulée avec une qualité « {result.get('qualite_seance', 'moyenne')} ».

    {result.get('resume_court', '')}

    Lien rapport : http://192.168.100.7:8000/patients/{seance_id}/detail/

    Cordialement,
    Système de surveillance hémodialyse"""
    
    
    return JsonResponse({
        "status": "ok",
    "seance_id":     seance_id,
    "nb_alertes":    len(alertes_list),
    "duree_minutes": duree_minutes,
    "rapport_url":   f"http://192.168.100.7:8000/patients/{seance_id}/detail/",
    "email_body":    email_body,
    "email_subject": f"⚠️ Séance difficile — {first_name} {last_name} — {date_str}",
    **result
})



# =========================
# AGENT 4 — NOTIF MÉDECIN
# =========================
@csrf_exempt
def notif_medecin(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)

    try:
        body = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "invalid json"}, status=400)

    message    = body.get("message", "")
    machine_id = body.get("machine_id", "A1")
    seance_id  = body.get("seance_id", None)
    source     = body.get("source", "alerte")

    if not message:
        return JsonResponse({"error": "missing message"}, status=400)

    fallback = "Contacter le médecin immédiatement."
    try:
        conseil = call_qwen(f"URGENT médecin: {message}", niveau="ROUGE", timeout=120)
        if not conseil:
            conseil = fallback
    except Exception as e:
        conseil = f"{fallback} (IA indisponible: {e})"

    return JsonResponse({
        "status":          "notified",
        "source":          source,
        "machine_id":      machine_id,
        "seance_id":       seance_id,
        "message":         message,
        "conseil_urgence": conseil,
    })


# =========================
# GET DEBIT FOR RASPI
# =========================
def get_debit(request):
    if request.method != "GET":
        return JsonResponse({"error": "GET only"}, status=405)

    machine_id = request.GET.get("machine_id")
    if not machine_id:
        return JsonResponse({"error": "missing machine_id"}, status=400)

    try:
        machine = Machine.objects.get(machine_id=machine_id)
    except Machine.DoesNotExist:
        return JsonResponse({"error": "machine unknown"}, status=404)

    seance = Seance.objects.filter(machine=machine, status="en cours").first()
    if not seance:
        return JsonResponse({"machine_id": machine_id, "debit": 60, "source": "default"})

    return JsonResponse({"machine_id": machine_id, "debit": seance.debit, "source": "seance"})


# =========================
# AGENT 6 — SUPERADMIN
# =========================
"""
AGENT SUPERADMIN — VERSION AVANCÉE
====================================
Architecture :
  - Qwen sur http://127.0.0.1:8001/conseil (serveur ASGI custom)
  - n8n comme middleware (webhook → Django → réponse)
  - Pas de function calling natif → le LLM répond en JSON texte
  - Le LLM décide SEUL quel outil appeler (plus de sa_detect_intent)
  - Fallback solide à chaque étape
"""

import json
import re
import string
import secrets
import logging
import requests

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Q
from django.contrib.auth.hashers import make_password

from accounts.models import User, Role
from machines.models import Machine, RaspiDevice
from seances.models import Seance, PreSessionMeasurements, PostSessionMeasurements
from patients.models import Patient
from monitoring.models import VitalReading, Alerte, ConversationLog

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

QWEN_URL   = "http://127.0.0.1:8001/conseil"
AGENT_URL  = "http://127.0.0.1:8001/agent/"   # nouvel endpoint agent
MAX_ITER   = 10
TIMEOUT_S  = 120

ACTION_TOOLS = {"create_user", "toggle_user", "delete_user", "start_seance", "close_seance"}

# ═══════════════════════════════════════════════════════════════
# SCHÉMA DES OUTILS — Injecté dans le prompt système
# ═══════════════════════════════════════════════════════════════

TOOLS_SCHEMA = [
    {
        "name": "get_stats",
        "description": "Retourne les statistiques globales du système (séances, alertes, machines, utilisateurs).",
        "parameters": {}
    },
    {
        "name": "list_alertes",
        "description": "Liste les dernières alertes. Filtrable par niveau (ROUGE, JAUNE, ALL) et limite.",
        "parameters": {
            "niveau": "ROUGE|JAUNE|ALL (défaut: ALL)",
            "limit": "entier (défaut: 10)"
        }
    },
    {
        "name": "list_seances",
        "description": "Liste les séances. Filtrable par status.",
        "parameters": {
            "status": "en cours|terminée|ALL (défaut: ALL)",
            "limit": "entier (défaut: 10)"
        }
    },
    {
        "name": "list_users",
        "description": "Liste les utilisateurs. Filtrable par rôle et état.",
        "parameters": {
            "role": "Docteur|Infirmier|Admin|SuperAdmin|ALL (défaut: ALL)",
            "actif": "true|false|ALL (défaut: ALL)",
            "limit": "entier (défaut: 20)"
        }
    },
    {
        "name": "list_machines",
        "description": "Liste toutes les machines et leur statut.",
        "parameters": {
            "status": "Prete|En cours|Maintenance|ALL (défaut: ALL)"
        }
    },
    {
        "name": "get_seance_detail",
        "description": "Retourne le détail complet d'une séance : mesures vitales et alertes récentes.",
        "parameters": {
            "seance_id": "UUID de la séance (obligatoire)"
        }
    },
    {
        "name": "search_patient",
        "description": "Recherche les séances d'un patient par son nom ou prénom.",
        "parameters": {
            "query": "nom ou prénom du patient (obligatoire)"
        }
    },
    {
        "name": "create_user",
        "description": "Crée un nouvel utilisateur dans le système.",
        "parameters": {
            "username": "identifiant unique (obligatoire)",
            "email": "adresse email (obligatoire)",
            "role": "Docteur|Infirmier|Admin|SuperAdmin (obligatoire)"
        }
    },
    {
        "name": "toggle_user",
        "description": "Active ou désactive un compte utilisateur.",
        "parameters": {
            "username": "identifiant de l'utilisateur (obligatoire)",
            "actif": "true pour activer, false pour désactiver (obligatoire)"
        }
    },
    {
        "name": "delete_user",
        "description": "Supprime définitivement un utilisateur du système.",
        "parameters": {
            "username": "identifiant de l'utilisateur à supprimer (obligatoire)"
        }
    },
    {
        "name": "start_seance",
        "description": "Lance (démarre) une séance en statut 'en cours'.",
        "parameters": {
            "seance_id": "UUID de la séance (obligatoire)"
        }
    },
    {
        "name": "close_seance",
        "description": "Clôture une séance active, la passe en statut 'terminée'.",
        "parameters": {
            "seance_id": "UUID de la séance (obligatoire)"
        }
    },
    {
        "name": "list_patients",
        "description": "Liste tous les patients enregistrés dans le système.",
        "parameters": {
            "query": "nom ou prénom pour filtrer (optionnel)",
            "limit": "entier (défaut: 20)"
        }
    },
    {
        "name": "get_pre_measurements",
        "description": "Retourne les mesures pré-séance d'un patient (pression artérielle, poids, fréquence cardiaque, température, saturation).",
        "parameters": {
            "patient_name": "nom ou prénom du patient (obligatoire)"
        }
    },
    {
        "name": "get_post_measurements",
        "description": "Retourne les mesures post-séance d'un patient (pression artérielle, poids, fréquence cardiaque, température, saturation).",
        "parameters": {
            "patient_name": "nom ou prénom du patient (optionnel)",
            "date": "date au format YYYY-MM-DD (optionnel, défaut: aujourd'hui)"
        }
    },
    {
        "name": "list_raspi",
        "description": "Liste tous les Raspberry Pi, leur état (actif/inactif), la machine associée et la dernière connexion.",
        "parameters": {
            "actif": "true|false|ALL (défaut: ALL)"
        }
    },
]

# ═══════════════════════════════════════════════════════════════
# PROMPT SYSTÈME — Le LLM y trouve tout ce dont il a besoin
# ═══════════════════════════════════════════════════════════════

def _build_system_prompt() -> str:
    return """Tu es l'Agent SuperAdmin d'un système médical de dialyse.
Tu dois répondre UNIQUEMENT en JSON valide. Jamais de texte libre.

=== OUTILS DISPONIBLES ===
- get_stats : statistiques globales (aucun paramètre)
- list_alertes : niveau=ROUGE|JAUNE|ALL, limit=entier
- list_seances : status=en cours|terminée|ALL, limit=entier
- list_users : role=Docteur|Infirmier|Admin|SuperAdmin|ALL, actif=true|false|ALL, limit=entier
- list_machines : status=Prete|En cours|Maintenance|ALL
- get_seance_detail : seance_id=UUID
- search_patient : query=nom_du_patient
- create_user : username=str, email=str, role=Docteur|Infirmier|Admin|SuperAdmin
- toggle_user : username=str, actif=true|false
- delete_user : username=str
- start_seance : seance_id=UUID
- close_seance : seance_id=UUID

=== FORMAT DE RÉPONSE OBLIGATOIRE ===
Pour appeler un outil :
{"action": "nom_outil", "action_input": {"param1": "valeur1"}}

Pour répondre à l'utilisateur :
{"final_answer": "réponse en français", "type": "info"}
{"final_answer": "réponse en français", "type": "action"}

=== EXEMPLES CONCRETS ===

USER: liste les utilisateurs
TOI: {"action": "list_users", "action_input": {"actif": "ALL"}}

USER: crée un utilisateur username=karim role=docteur email=karim@hopital.dz
TOI: {"action": "create_user", "action_input": {"username": "karim", "email": "karim@hopital.dz", "role": "Docteur"}}

USER: username amina role docteur mail amina@enis.tn
TOI: {"action": "create_user", "action_input": {"username": "amina", "email": "amina@enis.tn", "role": "Docteur"}}

USER: crée un infirmier nommé salim avec salim@clinic.tn
TOI: {"action": "create_user", "action_input": {"username": "salim", "email": "salim@clinic.tn", "role": "Infirmier"}}

USER: stats globales
TOI: {"action": "get_stats", "action_input": {}}

USER: alertes rouges
TOI: {"action": "list_alertes", "action_input": {"niveau": "ROUGE", "limit": 10}}

USER: désactive l'utilisateur karim
TOI: {"action": "toggle_user", "action_input": {"username": "karim", "actif": "false"}}

USER: supprime l'utilisateur test
TOI: {"action": "delete_user", "action_input": {"username": "test"}}

USER: [OBSERVATION] {"users": [{"username": "karim", "email": "k@h.dz", "role": "Docteur", "actif": true}]}
TOI: {"final_answer": "1 utilisateur trouvé : karim (Docteur, actif).", "type": "info"}

USER: [OBSERVATION] {"success": true, "message": "Utilisateur 'amina' créé avec le rôle Docteur.", "temporary_password": "Xk9#mQ2p"}
TOI: {"final_answer": "Utilisateur amina créé avec succès avec le rôle Docteur.", "type": "action"}

=== RÈGLES CRITIQUES ===
1. Réponds TOUJOURS avec un JSON valide — jamais de texte libre.
2. Extrait username, email et role directement depuis le message utilisateur, même si le format est informel.
3. Un email contient toujours @. Un username est un mot simple sans @.
4. Pour create_user : username + email + role sont TOUJOURS dans le message si l'utilisateur les a fournis.
5. Ne dis JAMAIS que des infos manquent si elles sont présentes dans le message.
6. Après une OBSERVATION, génère toujours un final_answer.
7. JAMAIS de markdown, JAMAIS de ``` dans ta réponse.
"""

# ═══════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════

def _gen_password(length=10) -> str:
    chars = string.ascii_letters + string.digits + "!@#$"
    return ''.join(secrets.choice(chars) for _ in range(length))


def _call_qwen(messages: list, timeout: int = TIMEOUT_S) -> str:
    """
    Appelle le serveur Qwen via /agent/ — endpoint dédié ReAct.
    Reçoit une liste de messages structurés.
    Retourne la décision JSON brute du modèle.
    """
    try:
        resp = requests.post(
            AGENT_URL,
            json={"messages": messages},
            timeout=timeout,
            headers={"Content-Type": "application/json"},
        )
        resp.raise_for_status()
        data = resp.json()

        if data.get("decision"):
            return json.dumps(data["decision"], ensure_ascii=False)

        return data.get("raw", data.get("conseil", "")).strip()

    except requests.Timeout:
        logging.error("Qwen /agent/ timeout")
        return ""
    except Exception as e:
        logging.error(f"Qwen /agent/ error: {e}")
        return ""


def _call_qwen_free(prompt: str, timeout: int = TIMEOUT_S) -> str:
    """
    Appelle le serveur Qwen via /conseil/ pour les questions générales.
    Pas de JSON forcé — Qwen répond en texte naturel.
    """
    try:
        resp = requests.post(
            QWEN_URL,
            json={"message": prompt, "niveau": "GENERAL"},
            timeout=timeout,
            headers={"Content-Type": "application/json"},
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("conseil", "").strip()

    except requests.Timeout:
        logging.error("Qwen /conseil/ timeout")
        return ""
    except Exception as e:
        logging.error(f"Qwen /conseil/ error: {e}")
        return ""


def _parse_llm_json(raw: str) -> dict | None:
    """
    Extrait et parse le JSON de la réponse du LLM.
    Gère les cas où le LLM ajoute du texte avant/après.
    """
    if not raw:
        return None

    # Nettoyer les balises markdown
    clean = re.sub(r"```json|```", "", raw).strip()

    # Chercher le premier bloc JSON valide
    # Stratégie 1 : toute la réponse est un JSON
    try:
        parsed = json.loads(clean)
        if isinstance(parsed, dict):
            return parsed
    except Exception:
        pass

    # Stratégie 2 : extraire le premier {...} dans le texte
    match = re.search(r"\{[\s\S]*\}", clean)
    if match:
        try:
            parsed = json.loads(match.group())
            if isinstance(parsed, dict):
                return parsed
        except Exception:
            pass

    return None


def _fallback_response(tool_name: str, result: dict) -> str:
    """Génère une réponse de fallback lisible si le LLM échoue."""

    if result.get("error"):
        return f"Erreur : {result['error']}"

    if tool_name == "list_patients":
        return f"{len(result.get('patients', []))} patient(s) trouvé(s)."

    if tool_name == "get_pre_measurements":
        r = result.get("pre_measurements", [])
        if r:
            m = r[0]
            return (f"Mesures pré-séance de {m['patient']} ({m['date_seance']}) : "
                    f"PA={m['pression_arterielle']}, poids={m['poids_kg']}kg, "
                    f"FC={m['frequence_cardiaque']}bpm, T°={m['temperature']}°C, SpO2={m['saturation']}%.")
        return result.get("error", "Aucune mesure trouvée.")

    if tool_name == "get_post_measurements":
        r = result.get("post_measurements", [])
        if r:
            m = r[0]
            return (f"Mesures post-séance de {m['patient']} ({m['date_seance']}) : "
                    f"PA={m['pression_arterielle']}, poids={m['poids_kg']}kg, "
                    f"FC={m['frequence_cardiaque']}bpm, T°={m['temperature']}°C, SpO2={m['saturation']}%.")
        return result.get("message", "Aucune mesure post-séance trouvée.")

    if tool_name == "list_raspi":
        raspis = result.get("raspis", [])
        actifs = sum(1 for r in raspis if r["actif"])
        return f"{len(raspis)} Raspberry Pi — {actifs} actifs, {len(raspis)-actifs} inactifs."

    if tool_name == "create_user":
        if result.get("success"):
            return f"Utilisateur '{result.get('message', '')}' créé avec succès."
        return f"Échec de création : {result.get('error', 'erreur inconnue')}"

    if tool_name == "toggle_user":
        return result.get("message", "Utilisateur mis à jour.")

    if tool_name == "delete_user":
        return result.get("message", "Utilisateur supprimé.")

    if tool_name == "start_seance":
        return result.get("message", "Séance lancée.")

    if tool_name == "close_seance":
        return result.get("message", "Séance clôturée.")

    if tool_name == "get_stats":
        s = result
        return (
            f"Système : {s.get('total_seances', 0)} séances dont {s.get('seances_actives', 0)} en cours, "
            f"{s.get('total_alertes', 0)} alertes ({s.get('alertes_rouge', 0)} rouges), "
            f"{s.get('total_users', 0)} utilisateurs, {s.get('total_machines', 0)} machines."
        )

    if "alertes" in result:
        return f"{len(result['alertes'])} alerte(s) trouvée(s)."

    if "users" in result:
        return f"{len(result['users'])} utilisateur(s) trouvé(s)."

    if "seances" in result:
        return f"{len(result['seances'])} séance(s) trouvée(s)."

    if "machines" in result:
        return f"{len(result['machines'])} machine(s) trouvée(s)."

    return "Opération effectuée."


def _check_missing_params(tool_name: str, params: dict) -> list:
    """Vérifie les paramètres obligatoires pour chaque outil."""
    required = {
        "create_user":    ["username", "email", "role"],
        "toggle_user":    ["username", "actif"],
        "delete_user":    ["username"],
        "start_seance":   ["seance_id"],
        "close_seance":   ["seance_id"],
        "get_seance_detail": ["seance_id"],
        "search_patient": ["query"],
    }
    needed = required.get(tool_name, [])
    return [p for p in needed if not params.get(p)]


# ═══════════════════════════════════════════════════════════════
# EXÉCUTION DES OUTILS (inchangé — votre logique Django)
# ═══════════════════════════════════════════════════════════════

def sa_execute_tool(tool_name: str, params: dict) -> dict:
    try:
        if tool_name == "get_stats":
            return {
                "total_seances":     Seance.objects.count(),
                "seances_actives":   Seance.objects.filter(status="en cours").count(),
                "seances_terminees": Seance.objects.filter(status="terminée").count(),
                "total_mesures":     VitalReading.objects.count(),
                "total_alertes":     Alerte.objects.count(),
                "alertes_rouge":     Alerte.objects.filter(niveau="ROUGE").count(),
                "alertes_jaune":     Alerte.objects.filter(niveau="JAUNE").count(),
                "total_machines":    Machine.objects.count(),
                "machines_prete":    Machine.objects.filter(status="Prete").count(),
                "machines_actives":  Machine.objects.exclude(status="Prete").count(),
                "total_users":       User.objects.count(),
                "users_actifs":      User.objects.filter(etat=True).count(),
            }

        elif tool_name == "list_alertes":
            niveau = params.get("niveau", "ALL")
            limit  = int(params.get("limit", 10))
            qs = Alerte.objects.select_related("reading__seance__patient", "reading__seance__machine")
            if niveau in ("ROUGE", "JAUNE"):
                qs = qs.filter(niveau=niveau)
            qs = qs.order_by("-timestamp")[:limit]
            return {"alertes": [
                {
                    "id":        a.id,
                    "niveau":    a.niveau,
                    "message":   a.message,
                    "timestamp": a.timestamp.strftime("%Y-%m-%d %H:%M"),
                    "patient":   f"{a.reading.seance.patient.first_name} {a.reading.seance.patient.last_name}"
                                 if a.reading and a.reading.seance and a.reading.seance.patient else "—",
                    "machine":   a.reading.seance.machine.machine_id
                                 if a.reading and a.reading.seance and a.reading.seance.machine else "—",
                    "conseil":   a.conseil or "—",
                }
                for a in qs
            ]}

        elif tool_name == "list_seances":
            status = params.get("status", "ALL")
            limit  = int(params.get("limit", 10))
            qs = Seance.objects.select_related("patient", "machine")
            if status != "ALL":
                qs = qs.filter(status=status)
            qs = qs.order_by("-id")[:limit]
            return {"seances": [
                {
                    "id":         str(s.id),
                    "status":     s.status,
                    "patient":    f"{s.patient.first_name} {s.patient.last_name}" if s.patient else "—",
                    "machine":    s.machine.machine_id if s.machine else "—",
                    "date":       str(s.session_date) if hasattr(s, "session_date") and s.session_date else "—",
                    "nb_alertes": Alerte.objects.filter(reading__seance=s).count(),
                }
                for s in qs
            ]}

        elif tool_name == "list_users":
            role  = params.get("role", "ALL")
            actif = params.get("actif", "ALL")
            limit = int(params.get("limit", 20))
            qs = User.objects.select_related("role")
            if role != "ALL":
                qs = qs.filter(role__name__iexact=role)
            if actif == "true":    qs = qs.filter(etat=True)
            elif actif == "false": qs = qs.filter(etat=False)
            qs = qs.order_by("username")[:limit]
            return {"users": [
                {
                    "username": u.username,
                    "email":    u.email,
                    "role":     u.role.name if u.role else "—",
                    "actif":    u.etat
                }
                for u in qs
            ]}

        elif tool_name == "list_machines":
            status = params.get("status", "ALL")
            qs = Machine.objects.all()
            if status != "ALL":
                qs = qs.filter(status=status)
            return {"machines": [
                {
                    "machine_id": m.machine_id,
                    "status":     m.status,
                    "location":   getattr(m, "location", "—")
                }
                for m in qs
            ]}

        elif tool_name == "get_seance_detail":
            seance_id = params.get("seance_id")
            s = Seance.objects.select_related("patient", "machine").get(id=seance_id)
            readings = VitalReading.objects.filter(seance=s).order_by("-timestamp")[:5]
            alertes  = Alerte.objects.filter(reading__seance=s).order_by("-timestamp")[:5]
            return {
                "seance": {
                    "id":      str(s.id),
                    "status":  s.status,
                    "patient": f"{s.patient.first_name} {s.patient.last_name}" if s.patient else "—",
                    "machine": s.machine.machine_id if s.machine else "—",
                    "date":    str(getattr(s, "session_date", "—")),
                },
                "dernieres_mesures": [
                    {
                        "timestamp":  r.timestamp.strftime("%H:%M:%S"),
                        "Qb":         r.Debit_sang,
                        "PTM":        r.PTM,
                        "PA":         r.PA,
                        "PV":         r.PV,
                        "UF_rate":    r.Taux_UF,
                        "UF_volume":  r.Volume_UF,
                        "Heparine":   r.Heparine,
                    }
                    for r in readings
                ],
                "alertes_recentes": [
                    {
                        "niveau":    a.niveau,
                        "message":   a.message,
                        "timestamp": a.timestamp.strftime("%H:%M:%S"),
                    }
                    for a in alertes
                ],
            }

        elif tool_name == "create_user":
            username  = str(params.get("username", "")).strip()
            email     = str(params.get("email", "")).strip()
            role_name = str(params.get("role", "")).strip()

            if not username or not email or not role_name:
                return {"error": "username, email et role sont tous obligatoires."}
            if User.objects.filter(username=username).exists():
                return {"error": f"L'utilisateur '{username}' existe déjà."}
            if User.objects.filter(email=email).exists():
                return {"error": f"L'email '{email}' est déjà utilisé."}
            try:
                role = Role.objects.get(name__iexact=role_name)
            except Role.DoesNotExist:
                return {"error": f"Rôle '{role_name}' introuvable. Rôles valides : Docteur, Infirmier, Admin, SuperAdmin."}

            tmp_pw = _gen_password()
            user = User.objects.create(
                username=username,
                email=email,
                role=role,
                etat=True,
                password=make_password(tmp_pw),
            )
            return {
                "success":            True,
                "message":            f"Utilisateur '{username}' créé avec le rôle {role_name}.",
                "temporary_password": tmp_pw,
                "user_id":            user.id,
            }

        elif tool_name == "toggle_user":
            username = str(params.get("username", "")).strip()
            actif    = str(params.get("actif", "true")).lower() == "true"
            try:
                user = User.objects.get(username=username)
            except User.DoesNotExist:
                return {"error": f"Utilisateur '{username}' introuvable."}
            user.etat = actif
            user.save(update_fields=["etat"])
            etat_str = "activé" if actif else "désactivé"
            return {"success": True, "message": f"Utilisateur '{username}' {etat_str}."}

        elif tool_name == "delete_user":
            username = str(params.get("username", "")).strip()
            if not username:
                return {"error": "username est obligatoire."}
            try:
                user = User.objects.get(username=username)
            except User.DoesNotExist:
                return {"error": f"Utilisateur '{username}' introuvable."}
            user.delete()
            return {"success": True, "message": f"Utilisateur '{username}' supprimé définitivement."}

        elif tool_name == "start_seance":
            seance_id = params.get("seance_id")
            if not seance_id:
                return {"error": "seance_id est obligatoire."}
            try:
                s = Seance.objects.get(id=seance_id)
                if s.status == "en cours":
                    return {"error": "Cette séance est déjà en cours."}
                s.status = "en cours"
                s.save(update_fields=["status"])
                return {"success": True, "message": f"Séance {seance_id} lancée."}
            except Seance.DoesNotExist:
                return {"error": f"Séance {seance_id} introuvable."}

        elif tool_name == "close_seance":
            seance_id = params.get("seance_id")
            if not seance_id:
                return {"error": "seance_id est obligatoire."}
            try:
                s = Seance.objects.get(id=seance_id)
                if s.status == "terminée":
                    return {"error": "Cette séance est déjà terminée."}
                s.status = "terminée"
                s.save(update_fields=["status"])
                return {"success": True, "message": f"Séance {seance_id} clôturée."}
            except Seance.DoesNotExist:
                return {"error": f"Séance {seance_id} introuvable."}

        elif tool_name == "search_patient":
            query = str(params.get("query", "")).strip()
            seances = Seance.objects.select_related("patient", "machine").filter(
                Q(patient__first_name__icontains=query) |
                Q(patient__last_name__icontains=query)
            ).order_by("-id")[:10]
            return {"seances": [
                {
                    "id":         str(s.id),
                    "status":     s.status,
                    "patient":    f"{s.patient.first_name} {s.patient.last_name}" if s.patient else "—",
                    "machine":    s.machine.machine_id if s.machine else "—",
                    "nb_alertes": Alerte.objects.filter(reading__seance=s).count(),
                }
                for s in seances
            ]}

        elif tool_name == "list_patients":
            query = str(params.get("query", "")).strip()
            limit = int(params.get("limit", 20))
            qs = Patient.objects.all().order_by("last_name", "first_name")
            if query:
                qs = qs.filter(
                    Q(first_name__icontains=query) | Q(last_name__icontains=query)
                )
            qs = qs[:limit]
            return {"patients": [
                {
                    "id":               p.id,
                    "nom":              f"{p.first_name} {p.last_name}",
                    "age":              p.age,
                    "groupe_sanguin":   p.groupe_sanguin,
                    "type_dialyse":     p.type_de_dialyse,
                    "telephone":        p.telephone,
                    "antecedents":      p.antecedents_medicaux or "—",
                }
                for p in qs
            ]}

        elif tool_name == "get_pre_measurements":
            patient_name = str(params.get("patient_name", "")).strip()
            if not patient_name:
                return {"error": "patient_name est obligatoire."}
            seances = Seance.objects.select_related("patient").filter(
                Q(patient__first_name__icontains=patient_name) |
                Q(patient__last_name__icontains=patient_name)
            ).order_by("-session_date")
            results = []
            for s in seances:
                try:
                    pre = s.pre_measurements
                    results.append({
                        "patient":         f"{s.patient.first_name} {s.patient.last_name}",
                        "date_seance":     str(s.session_date) if s.session_date else "—",
                        "pression_arterielle": pre.blood_pressure or "—",
                        "poids_kg":        pre.weight,
                        "frequence_cardiaque": pre.heart_rate,
                        "temperature":     pre.temperature,
                        "saturation":      pre.saturation,
                    })
                except PreSessionMeasurements.DoesNotExist:
                    pass
            if not results:
                return {"error": f"Aucune mesure pré-séance trouvée pour '{patient_name}'."}
            return {"pre_measurements": results}

        elif tool_name == "get_post_measurements":
            patient_name = str(params.get("patient_name", "")).strip()
            date_filter  = str(params.get("date", "")).strip()
            from django.utils import timezone
            import datetime
            qs = Seance.objects.select_related("patient").order_by("-session_date")
            if patient_name:
                qs = qs.filter(
                    Q(patient__first_name__icontains=patient_name) |
                    Q(patient__last_name__icontains=patient_name)
                )
            if date_filter:
                try:
                    d = datetime.date.fromisoformat(date_filter)
                    qs = qs.filter(session_date=d)
                except ValueError:
                    pass
            else:
                today = timezone.now().date()
                qs = qs.filter(session_date=today)
            results = []
            for s in qs:
                try:
                    post = s.post_measurements
                    results.append({
                        "patient":         f"{s.patient.first_name} {s.patient.last_name}",
                        "date_seance":     str(s.session_date) if s.session_date else "—",
                        "pression_arterielle": post.blood_pressure or "—",
                        "poids_kg":        post.weight,
                        "frequence_cardiaque": post.heart_rate,
                        "temperature":     post.temperature,
                        "saturation":      post.saturation,
                    })
                except PostSessionMeasurements.DoesNotExist:
                    pass
            if not results:
                return {"message": "Aucune mesure post-séance trouvée pour ce filtre.", "post_measurements": []}
            return {"post_measurements": results}

        elif tool_name == "list_raspi":
            actif  = params.get("actif", "ALL")
            qs = RaspiDevice.objects.select_related("machine").all()
            if actif == "true":    qs = qs.filter(is_active=True)
            elif actif == "false": qs = qs.filter(is_active=False)
            from django.utils import timezone
            now = timezone.now()
            return {"raspis": [
                {
                    "raspi_id":    r.raspi_id,
                    "description": r.description or "—",
                    "machine":     r.machine.machine_id if r.machine else "Non assigné",
                    "actif":       r.is_active,
                    "derniere_connexion": (
                        r.last_seen.strftime("%Y-%m-%d %H:%M") if r.last_seen else "Jamais"
                    ),
                    "minutes_depuis_connexion": (
                        int((now - r.last_seen).total_seconds() // 60)
                        if r.last_seen else None
                    ),
                }
                for r in qs
            ]}

        else:
            return {"error": f"Outil '{tool_name}' inconnu."}

    except Exception as e:
        logging.error(f"Tool error [{tool_name}]: {e}")
        return {"error": f"Erreur lors de l'exécution de {tool_name} : {str(e)}"}


# ═══════════════════════════════════════════════════════════════
# BOUCLE REACT PRINCIPALE — Le LLM décide tout
# ═══════════════════════════════════════════════════════════════

def _pre_parse_question(question: str) -> dict | None:
    """
    Pré-parseur de secours : extrait l'intention directement depuis le texte
    quand le LLM répond en texte libre au lieu de JSON.
    Couvre les patterns les plus fréquents.
    """
    q = question.strip()
    ql = q.lower()

    # ── create_user ───────────────────────────────────────────
    email_m = re.search(r"[\w.+-]+@[\w.-]+\.[a-z]{2,}", q)
    if email_m:
        email = email_m.group(0)

        # Mots à ignorer pour l'extraction du username
        SKIP_WORDS = {
            "cree", "crée", "créer", "creer", "un", "une", "user", "utilisateur",
            "docteur", "doctor", "infirmier", "infirmière", "admin", "superadmin",
            "avec", "le", "la", "les", "mail", "email", "role", "pour", "quest",
            "qui", "new", "nouveau", "ajouter", "add", "create", "et", "de", "du", "nommé", "appelé", "nommée", "username", "quest", "avec",
        }

        username = None

        # Pattern 1 : "username=xxx" ou "username xxx"
        um = re.search(r"username[=:\s]+(\w+)", ql)
        if um and um.group(1) not in SKIP_WORDS:
            username = um.group(1)

        # Pattern 2 : mot après "user" ou "utilisateur" — itérer tous les candidats
        if not username:
            for nm in re.finditer(r"(?:user|utilisateur)\s+(\w+)", ql):
                c = nm.group(1)
                if c not in SKIP_WORDS and len(c) >= 3:
                    username = c
                    break

        # Pattern 3 : mot après "nommé", "appelé", "nommée"
        if not username:
            nm = re.search(r"(?:nommé|appelé|nommée)\s+(\w+)", ql)
            if nm and nm.group(1) not in SKIP_WORDS:
                username = nm.group(1)

        # Pattern 4 : scanner tous les mots du message, prendre le premier
        # qui n'est pas un mot-clé connu et fait 3+ caractères
        if not username:
            for word in ql.split():
                w = word.strip(",:;.()")
                if len(w) >= 3 and w not in SKIP_WORDS and "@" not in w and w.isalnum():
                    username = w
                    break

        # Pattern 5 : mot juste avant l'email dans le texte original
        if not username:
            before = q[:email_m.start()].strip().split()
            if before:
                candidate = before[-1].strip(",:;")
                if len(candidate) >= 3 and "@" not in candidate and candidate.lower() not in SKIP_WORDS:
                    username = candidate.lower()

        # Extraire rôle
        role = None
        role_map = {
            "docteur": "Docteur", "doctor": "Docteur", "docter": "Docteur",
            "doctr": "Docteur", "doct": "Docteur",
            "infirmier": "Infirmier", "infirmière": "Infirmier", "infirm": "Infirmier",
            "admin": "Admin", "superadmin": "SuperAdmin",
        }
        for key, val in role_map.items():
            if key in ql:
                role = val
                break

        if username and role:
            return {"action": "create_user", "action_input": {
                "username": username, "email": email, "role": role
            }}

    # ── get_stats ─────────────────────────────────────────────
    if any(k in ql for k in ["stats", "statistiques", "dashboard", "tableau de bord", "global"]):
        return {"action": "get_stats", "action_input": {}}

    # ── list_alertes ──────────────────────────────────────────
    if any(k in ql for k in ["alerte", "alertes"]):
        niveau = "ROUGE" if "rouge" in ql else ("JAUNE" if "jaune" in ql else "ALL")
        return {"action": "list_alertes", "action_input": {"niveau": niveau, "limit": 10}}

    # ── list_seances ──────────────────────────────────────────
    if any(k in ql for k in ["séance", "seance", "séances", "seances"]) and        not any(k in ql for k in ["lancer", "démarrer", "clôturer", "fermer", "terminer"]):
        status = "en cours" if "cours" in ql else ("terminée" if "terminé" in ql else "ALL")
        return {"action": "list_seances", "action_input": {"status": status}}

    # ── list_users ────────────────────────────────────────────
    has_email  = bool(re.search(r"[\w.+-]+@[\w.-]+\.[a-z]{2,}", q))
    create_kw  = ["crée", "créer", "ajouter", "nouveau", "créé", "cree", "creer", "add", "create"]
    delete_kw  = ["supprimer", "supprime", "suprimer", "suprime", "delete", "effacer", "efface"]
    toggle_kw  = ["désactiver", "desactiver", "activer", "désactiv", "desactiv"]

    # Détecter le rôle demandé si précisé
    role_filter = None
    if any(k in ql for k in ["docteur", "doctor", "docter"]):
        role_filter = "Docteur"
    elif any(k in ql for k in ["infirmier", "infirmière", "infirm"]):
        role_filter = "Infirmier"
    elif "superadmin" in ql:
        role_filter = "SuperAdmin"
    elif "admin" in ql and "superadmin" not in ql:
        role_filter = "Admin"

    # Détecter si on filtre par état
    actif_filter = "ALL"
    if any(k in ql for k in ["inactif", "inactifs", "désactivé", "désactivés", "non actif"]):
        actif_filter = "false"
    elif any(k in ql for k in ["actif", "actifs", "activé", "activés"]):
        actif_filter = "true"

    user_kw = ["utilisateur", "user", "users", "utilisateurs",
               "docteur", "docteurs", "infirmier", "infirmiers", "infirmière",
               "admin", "admins", "superadmin", "inactif", "inactifs", "actifs"]
    if any(k in ql for k in user_kw) and \
       not has_email and \
       not any(k in ql for k in create_kw) and \
       not any(k in ql for k in delete_kw) and \
       not any(k in ql for k in toggle_kw):
        params = {"actif": actif_filter}
        if role_filter:
            params["role"] = role_filter
        return {"action": "list_users", "action_input": params}

    # ── list_machines ─────────────────────────────────────────
    if any(k in ql for k in ["machine", "machines"]):
        return {"action": "list_machines", "action_input": {}}

    # ── toggle_user ───────────────────────────────────────────
    TOGGLE_KW = ["désactiver", "desactiver", "activer", "désactiv", "desactiv", "activ"]
    if any(k in ql for k in TOGGLE_KW):
        actif = "false" if any(k in ql for k in ["désactiver","desactiver","désactiv","desactiv"]) else "true"
        username = None
        m = re.search(
            r"(?:désactiver?|desactiver?|activer?|désactiv\w*|desactiv\w*)"
            r"\s+(?:l[e\'\s]?|la\s+)?(?:utilisateurs?|users?)?\s*"
            r"([\w\-]{2,})",
            ql
        )
        if m:
            c = m.group(1).strip()
            if c not in {"user","utilisateur","utilisateurs","le","la","les","l"}:
                username = c
        if not username:
            # Chercher après "utilisateur" ou "user"
            m2 = re.search(r"(?:utilisateurs?|users?)\s+([\w\-]{2,})", ql)
            if m2:
                username = m2.group(1)
        if username:
            return {"action": "toggle_user", "action_input": {"username": username, "actif": actif}}

    # ── delete_user ───────────────────────────────────────────
    DELETE_KW = ["supprimer", "supprime", "suprimer", "suprime", "delete", "effacer", "efface"]
    if any(k in ql for k in DELETE_KW):
        username = None
        # Pattern : "supprime(r) [l(e/a/']utilisateur/user] username"
        m = re.search(
            r"(?:supprimer?|suprimer?|supprime?|suprime?|delete|effacer?|efface?)"
            r"\s+(?:l[e'\s]?|la\s+|les\s+)?"
            r"(?:utilisateurs?|users?)?\s*"
            r"([\w\-]{2,})",
            ql
        )
        if m:
            candidate = m.group(1).strip()
            # Ignorer les mots-clés
            if candidate not in {"user","utilisateur","utilisateurs","le","la","les","l"}:
                username = candidate
        if username:
            return {"action": "delete_user", "action_input": {"username": username}}

    # ── search_patient ────────────────────────────────────────
    if any(k in ql for k in ["chercher patient", "rechercher patient", "search patient"]):
        m = re.search(r"patient[=:\s]+(\w+)|(?:chercher|rechercher)\s+(\w+)", ql)
        if m:
            query = m.group(1) or m.group(2)
            return {"action": "search_patient", "action_input": {"query": query}}

    # ── list_patients ─────────────────────────────────────────
    if any(k in ql for k in ["liste les patients", "tous les patients", "list patients",
                               "les patients", "patients enregistrés"]):
        m = re.search(r"patient[=:\s]+(\w+)", ql)
        query = m.group(1) if m else ""
        return {"action": "list_patients", "action_input": {"query": query, "limit": 20}}

    # ── get_pre_measurements ──────────────────────────────────
    if any(k in ql for k in ["pré-séance", "pre-séance", "pre seance", "pré seance",
                               "mesures pré", "mesures pre", "avant séance", "avant seance"]):
        m = re.search(r"patient\s+(\w+)|du\s+patient\s+(\w+)|de\s+(\w+)", ql)
        name = ""
        if m:
            name = m.group(1) or m.group(2) or m.group(3) or ""
        return {"action": "get_pre_measurements", "action_input": {"patient_name": name}}

    # ── get_post_measurements ─────────────────────────────────
    if any(k in ql for k in ["post-séance", "post séance", "post seance",
                               "mesures post", "après séance", "apres seance"]):
        m = re.search(r"patient\s+(\w+)|du\s+patient\s+(\w+)|de\s+(\w+)", ql)
        name = ""
        if m:
            name = m.group(1) or m.group(2) or m.group(3) or ""
        from django.utils import timezone
        today = timezone.now().date().isoformat()
        return {"action": "get_post_measurements", "action_input": {
            "patient_name": name, "date": today
        }}

    # ── list_raspi ────────────────────────────────────────────
    if any(k in ql for k in ["raspberry", "raspi", "raspberries", "raspberry pi"]):
        actif = "true" if "actif" in ql else ("false" if "inactif" in ql else "ALL")
        return {"action": "list_raspi", "action_input": {"actif": actif}}

    return None


def _answer_general_question(question: str, conversation_history: list) -> dict:
    """
    Répond à une question générale sans outil.
    Qwen répond librement en français — médical ou non.
    """
    # Construire un prompt conversationnel simple
    history_text = ""
    for msg in conversation_history[-4:]:
        role    = msg.get("role", "user")
        content = msg.get("content", "")
        if role == "user":
            history_text += f"Utilisateur: {content}\n"
        elif role == "assistant":
            history_text += f"Assistant: {content}\n"

    prompt_messages = [
        {
            "role": "system",
            "content": (
                "Tu es l'agent IA SuperAdmin d'un système médical de dialyse appelé DialyseApp. "
                "Tu travailles dans un hôpital tunisien et tu aides les administrateurs à gérer le système. "
                "\n\n"
                "=== CE QUE TU PEUX FAIRE ===\n"
                "1. Gérer les utilisateurs : créer, activer, désactiver, supprimer un compte (médecin, infirmier, admin)\n"
                "2. Consulter les séances de dialyse : en cours, terminées, détail complet\n"
                "3. Consulter les alertes médicales : rouges (critiques) et jaunes (modérées)\n"
                "4. Consulter les machines de dialyse et les Raspberry Pi connectés\n"
                "5. Consulter les patients et leurs mesures pré/post séance\n"
                "6. Afficher les statistiques globales du système\n"
                "7. Lancer ou clôturer une séance\n"
                "\n"
                "=== EXEMPLES DE COMMANDES ===\n"
                "- 'liste les docteurs' → affiche tous les médecins\n"
                "- 'cree un user amina docteur amina@enis.tn' → crée un compte médecin\n"
                "- 'alertes rouges' → affiche les alertes critiques\n"
                "- 'stats globales' → statistiques du système\n"
                "- 'mesures pré-séance du patient ahmed' → mesures avant dialyse\n"
                "- 'état des raspberry pi' → état des appareils connectés\n"
                "\n"
                "Réponds en français, de façon claire et professionnelle. "
                "Pour les questions médicales sur la dialyse, réponds avec tes connaissances. "
                "Réponds en texte naturel — pas de JSON."
            )
        }
    ]

    # Ajouter l'historique
    for msg in conversation_history[-4:]:
        role    = msg.get("role", "user")
        content = msg.get("content", "")
        if role in ("user", "assistant") and content:
            prompt_messages.append({"role": role, "content": content})

    prompt_messages.append({"role": "user", "content": question})

    logging.warning(f"[ReAct] question générale → Qwen libre (/conseil/)")

    try:
        # Construire le prompt complet en texte pour /conseil/
        system_content = ""
        dialogue_parts = []
        for m in prompt_messages:
            role    = m.get("role", "user")
            content = m.get("content", "")
            if role == "system":
                system_content = content
            elif role == "assistant":
                dialogue_parts.append(f"Assistant: {content}")
            elif role == "user":
                dialogue_parts.append(f"Utilisateur: {content}")

        dialogue = "\n".join(dialogue_parts)
        full_prompt = f"{system_content}\n\n{dialogue}\nAssistant:"

        # Appel direct à /conseil/ — pas de JSON forcé
        raw = _call_qwen_free(full_prompt, timeout=TIMEOUT_S)

        if not raw:
            # Générer une réponse de fallback intelligente selon la question
            ql = question.lower()
            if any(k in ql for k in ["comment", "utiliser", "application", "aide", "help", "fonctionnalit"]):
                raw = (
                    "Je suis votre Agent SuperAdmin IA pour le système de dialyse. "
                    "Voici ce que je peux faire :\n\n"
                    "Gestion des utilisateurs : créer, activer, désactiver ou supprimer un compte médecin, infirmier ou admin.\n"
                    "Séances : lister les séances en cours ou terminées, voir le détail d\'une séance, lancer ou clôturer une séance.\n"
                    "Alertes : consulter les alertes rouges (critiques) et jaunes (modérées).\n"
                    "Patients : lister les patients, voir leurs mesures pré et post séance.\n"
                    "Machines : état des machines de dialyse et des Raspberry Pi.\n"
                    "Statistiques : tableau de bord global du système.\n\n"
                    "Exemples de commandes : \'liste les docteurs\', \'alertes rouges\', \'cree un user amina docteur amina@enis.tn\', \'stats globales\'."
                )
            elif any(k in ql for k in ["bonjour", "salut", "hello", "bonsoir"]):
                raw = "Bonjour ! Je suis votre Agent SuperAdmin IA. Comment puis-je vous aider aujourd\'hui ?"
            elif any(k in ql for k in ["merci", "thank"]):
                raw = "De rien ! N\'hésitez pas si vous avez d\'autres questions."
            else:
                raw = "Je suis votre Agent SuperAdmin IA. Je peux gérer les utilisateurs, séances, alertes, machines et patients. Posez-moi une question ou donnez-moi une commande."

        # Si Qwen retourne du JSON malgré tout, extraire le texte
        parsed = _parse_llm_json(raw)
        if parsed:
            reponse = (
                parsed.get("final_answer")
                or parsed.get("reponse")
                or parsed.get("message")
                or raw
            )
        else:
            reponse = raw.strip()

        return {
            "reponse":    reponse,
            "type":       "info",
            "donnees":    {},
            "tools_used": [],
            "iterations": 1,
        }
    except Exception as e:
        logging.error(f"[ReAct] general question error: {e}")
        ql = question.lower()
        if any(k in ql for k in ["bonjour", "salut", "hello"]):
            rep = "Bonjour ! Je suis votre Agent SuperAdmin IA. Comment puis-je vous aider ?"
        else:
            rep = "Je suis votre Agent SuperAdmin IA. Je peux gérer les utilisateurs, séances, alertes, machines et patients. Que souhaitez-vous faire ?"
        return {
            "reponse":    rep,
            "type":       "info",
            "donnees":    {},
            "tools_used": [],
            "iterations": 0,
        }


def sa_react_loop(question: str, conversation_history: list) -> dict:
    """
    Boucle ReAct où le LLM est le seul décideur.
    Plus de sa_detect_intent — le LLM choisit l'outil via JSON.
    """

    system_prompt = _build_system_prompt()

    # Construire les messages : system + historique récent + question
    messages = [{"role": "system", "content": system_prompt}]

    # Injecter les 6 derniers échanges pour la mémoire contextuelle
    for msg in conversation_history[-6:]:
        role    = msg.get("role", "user")
        content = msg.get("content", "")
        if role in ("user", "assistant") and content:
            messages.append({"role": role, "content": content})

    # Ajouter la question courante
    messages.append({"role": "user", "content": question})

    tools_log  = []
    iterations = 0
    last_raw   = ""

    # ══════════════════════════════════════════════════════════
    # ÉTAPE 0 : Pre-parser AVANT le LLM
    # Le LLM hallucine souvent final_answer sans appeler les outils.
    # Pour les intentions claires (create_user, stats, alertes...),
    # on exécute directement l'outil sans passer par le LLM.
    # Si aucun outil détecté → question générale → Qwen répond librement.
    # ══════════════════════════════════════════════════════════
    pre_intent = _pre_parse_question(question)

    # Cas : aucun outil détecté → question générale → Qwen répond directement
    if pre_intent is None:
        return _answer_general_question(question, conversation_history)

    if pre_intent and pre_intent.get("action"):
        tool_name   = pre_intent["action"]
        tool_params = pre_intent.get("action_input", {})
        logging.warning(f"[ReAct] pre-parser direct: tool={tool_name} params={tool_params}")

        tool_result = sa_execute_tool(tool_name, tool_params)
        tools_log.append({
            "tool":       tool_name,
            "params":     tool_params,
            "result":     str(tool_result)[:300],
            "result_raw": tool_result,
        })

        # Demander au LLM de formuler la réponse finale uniquement
        obs_str = json.dumps(tool_result, ensure_ascii=False, default=str)
        summary_messages = [
            {
                "role": "system",
                "content": (
                    "Tu es un assistant médical. "
                    "Résume ce résultat en 1-2 phrases françaises naturelles et claires. "
                    "Si le résultat contient un temporary_password, mentionne-le explicitement. "
                    "Réponds UNIQUEMENT avec ce JSON : {\"final_answer\": \"ta réponse\", \"type\": \"action\"} ou {\"final_answer\": \"ta réponse\", \"type\": \"info\"}"
                )
            },
            {
                "role": "user",
                "content": f"Action effectuée: {tool_name}\nRésultat: {obs_str}"
            }
        ]
        summary_raw  = _call_qwen(summary_messages, timeout=30)
        summary_step = _parse_llm_json(summary_raw)

        if summary_step and summary_step.get("final_answer"):
            final_text = summary_step["final_answer"]
        else:
            final_text = _fallback_response(tool_name, tool_result)

        # Ajouter le mot de passe dans la réponse si présent
        if tool_result.get("temporary_password"):
            pw = tool_result["temporary_password"]
            if pw not in final_text:
                final_text += f" Mot de passe temporaire : {pw}"

        type_reponse = "action" if tool_name in ACTION_TOOLS else "info"
        return {
            "reponse":    final_text,
            "type":       type_reponse,
            "donnees":    tool_result,
            "tools_used": tools_log,
            "iterations": 0,
        }

    # ══════════════════════════════════════════════════════════
    # ÉTAPE 1 : Boucle ReAct normale (questions ambiguës)
    # ══════════════════════════════════════════════════════════
    while iterations < MAX_ITER:
        iterations += 1

        # ── Appel LLM ────────────────────────────────────────
        raw = _call_qwen(messages, timeout=TIMEOUT_S)

        # ── Filet de sécurité : LLM répond final_answer sans avoir exécuté d'outil ──
        raw_step = _parse_llm_json(raw)
        if raw_step and "final_answer" in raw_step and not tools_log:
            # Le LLM hallucine une réponse — forcer le pre-parser
            forced = _pre_parse_question(question)
            if forced:
                logging.warning(f"[ReAct] LLM hallucination détectée → pre-parser forcé: {forced}")
                raw = json.dumps(forced, ensure_ascii=False)

        last_raw = raw
        logging.warning(f"[ReAct iter={iterations}] raw={raw[:200]}")

        # ── Parser la réponse JSON du LLM ────────────────────
        step = _parse_llm_json(raw)

        # Cas 1 : parsing échoué → fallback
        if step is None:
            logging.warning(f"[ReAct] JSON parse failed at iter={iterations}")
            # Si on a déjà des résultats d'outils, générer un fallback
            if tools_log:
                last_tool   = tools_log[-1]["tool"]
                last_result = tools_log[-1].get("result_raw", {})
                fallback_text = _fallback_response(last_tool, last_result)
                return {
                    "reponse":    fallback_text,
                    "type":       "action" if last_tool in ACTION_TOOLS else "info",
                    "donnees":    last_result,
                    "tools_used": tools_log,
                    "iterations": iterations,
                }
            # Sinon retourner le texte brut si c'est du texte naturel
            if raw and not raw.strip().startswith("{"):
                return {
                    "reponse":    raw.strip(),
                    "type":       "info",
                    "donnees":    {},
                    "tools_used": tools_log,
                    "iterations": iterations,
                }
            # Vraiment rien
            return {
                "reponse":    "Je n'ai pas pu traiter votre demande. Veuillez reformuler.",
                "type":       "error",
                "donnees":    {},
                "tools_used": tools_log,
                "iterations": iterations,
            }

        # Cas 2 : réponse finale
        if "final_answer" in step:
            final_text   = str(step.get("final_answer", "")).strip()
            type_reponse = str(step.get("type", "info")).strip()

            if not final_text:
                final_text = "Opération effectuée."

            # Forcer type=action si un outil d'action a été utilisé
            if any(t["tool"] in ACTION_TOOLS for t in tools_log):
                type_reponse = "action"

            # Récupérer les données du dernier outil exécuté
            donnees = tools_log[-1].get("result_raw", {}) if tools_log else {}

            return {
                "reponse":    final_text,
                "type":       type_reponse,
                "donnees":    donnees,
                "tools_used": tools_log,
                "iterations": iterations,
            }

        # Cas 3 : le LLM veut utiliser un outil
        if "action" in step:
            tool_name   = str(step.get("action", "")).strip().lower()
            tool_params = step.get("action_input", {})

            if not isinstance(tool_params, dict):
                tool_params = {}

            # Vérifier les paramètres obligatoires
            missing = _check_missing_params(tool_name, tool_params)
            if missing:
                # Demander au LLM de redemander les infos manquantes
                obs_content = json.dumps({
                    "error": f"Paramètres manquants pour {tool_name} : {', '.join(missing)}. Demande-les à l'utilisateur via final_answer."
                }, ensure_ascii=False)
            else:
                # Exécuter l'outil
                tool_result = sa_execute_tool(tool_name, tool_params)
                obs_content = json.dumps(tool_result, ensure_ascii=False, default=str)

                tools_log.append({
                    "tool":       tool_name,
                    "params":     tool_params,
                    "result":     obs_content[:300],
                    "result_raw": tool_result,
                })

                logging.warning(f"[ReAct] tool={tool_name} params={tool_params} result={obs_content[:150]}")

                # Pour les outils d'action : réponse directe sans re-demander au LLM
                # (évite que le LLM "hallucine" sur le résultat d'une action critique)
                if tool_name in ACTION_TOOLS:
                    # Demander au LLM de formuler la réponse finale
                    summary_messages = [
                        {
                            "role": "system",
                            "content": (
                                "Tu es un assistant médical. "
                                "Résume ce résultat d'action en 1-2 phrases français naturel. "
                                "Réponds UNIQUEMENT avec ce JSON : "
                                '{"final_answer": "ta réponse", "type": "action"}'
                            )
                        },
                        {
                            "role": "user",
                            "content": f"Action: {tool_name}\nRésultat: {obs_content}"
                        }
                    ]
                    summary_raw  = _call_qwen(summary_messages, timeout=30)
                    summary_step = _parse_llm_json(summary_raw)

                    if summary_step and summary_step.get("final_answer"):
                        final_text = summary_step["final_answer"]
                    else:
                        final_text = _fallback_response(tool_name, tool_result)

                    return {
                        "reponse":    final_text,
                        "type":       "action",
                        "donnees":    tool_result,
                        "tools_used": tools_log,
                        "iterations": iterations,
                    }

            # Réinjecter l'observation dans les messages pour la prochaine itération
            messages.append({
                "role":    "assistant",
                "content": json.dumps(step, ensure_ascii=False)
            })
            messages.append({
                "role":    "user",
                "content": f"[OBSERVATION] {obs_content}"
            })

            continue  # Prochaine itération

        # Cas 4 : JSON valide mais ni action ni final_answer
        logging.warning(f"[ReAct] Unexpected JSON step: {step}")
        break

    # ── Dépassement MAX_ITER : fallback ──────────────────────
    logging.warning(f"[ReAct] MAX_ITER={MAX_ITER} reached")

    if tools_log:
        last_tool   = tools_log[-1]["tool"]
        last_result = tools_log[-1].get("result_raw", {})
        return {
            "reponse":    _fallback_response(last_tool, last_result),
            "type":       "action" if last_tool in ACTION_TOOLS else "info",
            "donnees":    last_result,
            "tools_used": tools_log,
            "iterations": iterations,
        }

    return {
        "reponse":    "Je n'ai pas pu répondre après plusieurs tentatives. Veuillez reformuler.",
        "type":       "error",
        "donnees":    {},
        "tools_used": tools_log,
        "iterations": iterations,
    }


# ═══════════════════════════════════════════════════════════════
# VUE DJANGO
# ═══════════════════════════════════════════════════════════════

@csrf_exempt
def agent_superadmin(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST only"}, status=405)

    try:
        body = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "Invalid JSON body"}, status=400)

    question = str(body.get("question", "")).strip()
    if not question:
        return JsonResponse({"error": "missing question"}, status=400)

    conversation_history = body.get("history", [])
    session_id           = body.get("session_id", "unknown")

    logging.warning(f"[SuperAdmin] session={session_id} question={question[:100]}")

    try:
        result = sa_react_loop(question, conversation_history)
    except Exception as e:
        logging.error(f"[SuperAdmin] sa_react_loop crash: {e}")
        return JsonResponse({
            "status":     "error",
            "error":      str(e),
            "reponse":    "Une erreur interne s'est produite.",
            "type":       "error",
            "donnees":    {},
            "tools_used": [],
            "iterations": 0,
        }, status=500)

    # Log en base
    try:
        ConversationLog.objects.create(
            session_id=session_id,
            question=question,
            reponse=result.get("reponse", ""),
            tools_used=result.get("tools_used", []),
            iterations=result.get("iterations", 1),
            type_reponse=result.get("type", "info"),
        )
    except Exception as e:
        logging.warning(f"[SuperAdmin] ConversationLog failed: {e}")

    logging.warning(
        f"[SuperAdmin] type={result.get('type')} "
        f"iter={result.get('iterations')} "
        f"tools={[t['tool'] for t in result.get('tools_used', [])]}"
    )

    return JsonResponse({"status": "ok", "question": question, **result})
