SEUILS_DEFAUT = {
    "Debit_sang": {"min": 150, "max": 400, "crit_min": 100, "crit_max": 450, "unite": "mL/min",  "label": "Débit sanguin"},
    "PA":         {"min": 90,  "max": 180, "crit_min": 70,  "crit_max": 200, "unite": "mmHg",    "label": "Pression artérielle"},
    "PV":         {"min": 50,  "max": 250, "crit_min": 30,  "crit_max": 280, "unite": "mmHg",    "label": "Pression veineuse"},
    "PTM":        {"min": -50, "max": 300, "crit_min": -80, "crit_max": 350, "unite": "mmHg",    "label": "Pression transmembranaire"},
    "Taux_UF":    {"min": 0,   "max": 1000,"crit_min": 0,   "crit_max": 1200,"unite": "mL/h",    "label": "Taux UF"},
    "Volume_UF":  {"min": 0,   "max": 4000,"crit_min": 0,   "crit_max": 5000,"unite": "mL",      "label": "Volume UF"},
    "Heparine":   {"min": 0,   "max": 2000,"crit_min": 0,   "crit_max": 2500,"unite": "UI/h",    "label": "Héparine"},
}
 
 
def analyser_mesure(mesure):
    """
    Analyse un LiveMeasurement et retourne une liste d'alertes à créer.
    Compatible avec le modèle Alert de seances/models.py.
    Retourne: list of dict { alert_type, message, danger_level, recommended_action }
    """
    alertes = []
 
    for champ, s in SEUILS_DEFAUT.items():
        valeur = getattr(mesure, champ, None)
        if valeur is None:
            continue
 
        label  = s["label"]
        unite  = s["unite"]
        niveau = None
        message = None
        action  = None
 
        # CRITIQUE (HIGH)
        if valeur < s["crit_min"]:
            niveau  = "HIGH"
            message = f"🔴 CRITIQUE — {label} très bas : {valeur} {unite} (seuil critique : {s['crit_min']} {unite})"
            action  = f"Vérifier immédiatement la ligne. Alerter le médecin si {label} reste sous {s['crit_min']} {unite}."
        elif valeur > s["crit_max"]:
            niveau  = "HIGH"
            message = f"🔴 CRITIQUE — {label} très élevé : {valeur} {unite} (seuil critique : {s['crit_max']} {unite})"
            action  = f"Réduire le débit ou ajuster les paramètres. Alerter le médecin si {label} dépasse {s['crit_max']} {unite}."
 
        # ATTENTION (MEDIUM)
        elif valeur < s["min"]:
            niveau  = "MEDIUM"
            message = f"🟡 ATTENTION — {label} bas : {valeur} {unite} (normal min : {s['min']} {unite})"
            action  = f"Surveiller {label}. Vérifier les connexions et paramètres de la machine."
        elif valeur > s["max"]:
            niveau  = "MEDIUM"
            message = f"🟡 ATTENTION — {label} élevé : {valeur} {unite} (normal max : {s['max']} {unite})"
            action  = f"Surveiller {label}. Envisager un ajustement des paramètres de dialyse."
 
        if niveau:
            alertes.append({
                "alert_type":         label,
                "message":            message,
                "danger_level":       niveau,
                "recommended_action": action,
            })
 
    return alertes
