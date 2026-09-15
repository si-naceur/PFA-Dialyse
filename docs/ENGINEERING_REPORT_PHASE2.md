# Rapport d'ingénierie — PFA-Dialyse (Phase 2)

Projet : PFA-Dialyse — système de surveillance de dialyse (Django Web + API REST + Flutter + Raspberry Pi / MQTT / IA).
Date : 16/08/2026.

---

## A. Résumé exécutif

L'audit Phase 1 a identifié des placeholders, des routes mortes, des secrets en clair,
un désalignement d'environnement et une faille de persistance des alertes. La Phase 2
a corrigé tous ces points en appliquant strictement les règles du cahier des charges :
**le Web Django est la source de vérité**, aucune fonctionnalité n'a été supprimée,
**aucune donnée n'a été fabriquée**, et chaque groupe de correctifs a été validé
(`manage.py check/test`, `flutter analyze/test`).

Résultat : **31 tests Django OK** (venv 5.2.17 et système 5.2.17), **flutter analyze 0 issue**,
**19 tests Flutter OK**, build web OK, pipeline MQTT→Django→alertes vérifié en runtime,
et persistance des statuts d'alerte vérifiée en production locale.

## B. Correctifs réalisés (par priorité)

### P0 — Sécurité
- `PFA/settings.py` : `SECRET_KEY`, `DEBUG`, `ALLOWED_HOSTS`, `EMAIL_HOST_USER` /
  `EMAIL_HOST_PASSWORD` / `DEFAULT_FROM_EMAIL` désormais pilotés par variables
  d'environnement (fichier `.env.example` fourni). En l'absence de mot de passe SMTP,
  backend email console (dev non cassé, aucun envoi accidentel).
- Suppression du **mot de passe Gmail en clair** (`xnii qhqd arku qvuc`) du code source.
  ⚠️ **Action requise côté utilisateur : régénérer ce mot de passe d'application Gmail**
  car il a été exposé dans le dépôt.
- `api/views.py` et `accounts/views.py` : mots de passe générés via `secrets.token_urlsafe`
  au lieu de `random.choices` (PRNG non cryptographique, 8 caractères).

### P0 — Persistance des alertes (ack / resolve)
- `seances.Alert` : ajout du champ `status` (`NEW`/`ACK`/`RESOLVED`, défaut `NEW`) —
  migration `seances/0003_alert_status.py`.
- `api/views.py` : `api_alerts` retourne maintenant le **vrai** statut au lieu de `"NEW"`
  codé en dur ; filtre `?status=` appliqué aux deux sources (`monitoring.Alerte` +
  `seances.Alert`) ; `api_alert_ack` / `api_alert_resolve` **persistent** désormais le
  statut des alertes de séance (auparavant no-op).
- Flutter (`alerts_history`) consommait déjà `status` et raffraîchit après action — aucune
  modification nécessaire.
- Tests ajoutés dans `api/tests.py` : ack→ACK, resolve→RESOLVED, filtres par statut.

### P1 — KPIs réels (fini les zéros/4.8 codés en dur)
- `monitoring/views.py` dashboard : `kpi_machines_total` / `kpi_machines_available` réels
  (requêtes `Machine`).
- `accounts/views.py` nurses : `kpi_total_patients`, `kpi_active_sessions`,
  `kpi_scheduled_sessions`, `kpi_avg_load` calculés depuis la base.
- `api/views.py` : mêmes KPIs réels côté API ; `api_dashboard.active_alerts` compte les
  deux sources ; `rating` docteur passé de `4.8` (fabricé) à `0` (aucune donnée de
  notation n'existe dans le schéma — signalé explicitement dans le code) ;
  `sessionsCount` conservé à 0 car **aucune relation médecin→séance n'existe dans le
  schéma** (documenté, non inventé).
- Tests ajoutés : `test_dashboard_kpis_are_real_values`, `test_nurses_kpis_are_real_values`,
  `test_doctors_do_not_fabricate_rating`.

### P1 — Environnement réconcilié
- `requirements.txt` aligné sur le runtime réellement testé : Django `5.2.17`, +
  `djangorestframework`, `fastapi`, `openai`, `paho-mqtt`, `python-multipart`, `uvicorn`,
  `requests`, `Pillow`.
- **Venviupgraded** 3.1.12 → 5.2.17 (dépendances installées), `djongo` retiré
  (incompatible Django 5, config Mongo morte car `MongoRouter` force `default`).
- Les deux environnements passent les 31 tests.

### P1 — Pipeline IA / vision
- `producer.py` : URLs mortes corrigées (`/api/monitoring/save/`, `/monitoring/push/`
  → `{DJANGO_BASE_URL}/api/push/`), configuration 100 % par variables d'environnement
  (aucun ID matériel en dur), log de réponse Django ajouté.
- `server.py` : imports vérifiés sur les deux environnements ; les `print` non-ASCII
  (crash sur console cp1252 sans `-X utf8`) remplacés ; dépendances ajoutées.
  Fallback explicite conservé : les valeurs simulées sont **étiquetées `_source:
  "fallback"`**, jamais présentées comme réelles ; endpoint `/status/` expose le mode.
- **Vérifié en runtime** : `uvicorn server:app` → `/status/` (mode fallback) et
  `/analyze/` (POST image → JSON de valeurs + `_source: fallback`) répondent 200.

### P2 — Architecture Flutter « devices » complétée
- Ajout des couches manquantes conformément au pattern des autres features :
  `data/models/device_model.dart`, `data/repositories/devices_repository_impl.dart`,
  `domain/repositories/devices_repository.dart`.
- `devices_remote_datasource` refactoré pour utiliser le modèle ; le provider et la page
  passent par le repository (plus d'appel direct datasource).
- `flutter analyze` : 0 issue ; `flutter test` : 19/19.

### P2 — Contrainte d'intégrité des rôles
- `Role.name` : `unique=True` + migration de déduplication `accounts/0003_alter_role_name.py`
  qui repointe les utilisateurs des doublons (`Docteur` ids 6,7,8) vers le rôle conservé
  **avant** suppression (le `CASCADE` sur `User.role` aurait supprimé des utilisateurs).
- Base nettoyée : `Admin`, `Docteur`, `Infirmier` uniques ; `admin` conservé.

### P2 — API : 404 JSON sur identifiant de séance invalide
- Routes séances passées de `<uuid:session_id>` à `<str:session_id>` ; les vues gèrent
  déjà `ValueError/ValidationError` → `404 {"success": false}`. Vérifié en runtime :
  `/api/sessions/not-a-uuid/` et `.../start/` → 404 JSON (au lieu de 404 HTML Django).

### P2 — Protocole MQTT explicite
- `docs/MQTT_PROTOCOL.md` : protocole documenté (topic `dialysis/machine/{machine_id}`,
  clés du payload → champs `LiveMeasurement`, QoS 1, endpoints HTTP complémentaires).
- `edge_client.py`, `producer.py`, `mqtt_simulator.py`, `mqtt_listener.py` :
  brokers/ports/IDs/URLs configurables par variables d'environnement (plus aucun ID ou
  hôte codé en dur) ; API `paho.mqtt.Client` compatible (CallbackAPIVersion.VERSION2 avec
  repli).
- **Vérifié en runtime** : `mqtt_listener.py` + `mqtt_simulator.py --once` →
  `LiveMeasurement` créé (`Qb=280, PA=220`) et alerte `seances.Alert` `HIGH` générée.

### P2/P3 — Code mort supprimé
- `machines/signals.py` supprimé (importait des modèles inexistants
  `MachineModuleStatus`/`MachineTypeModule` et un champ `instance.type` absent — c'était
  un piège non câblé qui aurait crashé s'il avait été chargé).
- `monitoring/views.py` : 7 vues mortes sans URL supprimées (`live_alerts`, `ia_conseil`,
  `live_data`, `real_monitoring`, `push_measurement`, `ack_alert`, `resolve_alert`) —
  toutes dupliquées par les endpoints API câblés ; imports devenus inutiles nettoyés.
- Templates orphelins supprimés : `accounts/templates/register.html`,
  `accounts/templates/home.html` (non référencés par `render()`) et le fichier Python
  égaré `accounts/templates/decorator.py`.
- `VitalReading` / `ConversationLog` : **conservés** (modèles non utilisés mais la
  suppression exige une migration destructrice de tables — risque inutile, documenté).

## C. Spécification de l'architecture

```
┌────────────┐   HTTP/JSON   ┌──────────────────────┐
│  Flutter   │ ────────────▶ │  Django (Web + API)  │
│  (web/app) │ ◀──────────── │  PFA/settings.py     │
└────────────┘  X-Session-Id │  api/views.py        │
                             │  monitoring/views.py │
┌────────────┐   MQTT        │  accounts/views.py   │
│  RPi / Edge├─────────────▶ │        │             │
│  client    │ topic:        │        ▼             │
└────────────┘ dialysis/     │   SQLite (db.sqlite3)│
             machine/{id}    │  + media/ (photos)   │
                             └──────────────────────┘
       ┌────────────┐  HTTP   ▲
       │  server.py │ ────────┘  POST /api/push/
       │ (FastAPI)  │  /analyze/  (fallback HTTP)
       └────────────┘  + POST /api/push/ (pipeline HTTP)
```

- Authentification : session Django, `X-Session-Id` (Flutter Web) ou cookie `sessionid`.
- Flux alertes : `LiveMeasurement` → `check_thresholds()` (monitoring) + `analyser_mesure()`
  (seances), dédupliquées sur 5 min, statut persistant NEW→ACK→RESOLVED.
- Pipeline hardware : Raspberry Pi → MQTT (ou HTTP) → Django → DB → alertes ; IA locale
  (FastAPI + HF) pour la lecture d'écran avec fallback explicite.

## D. Lignes directrices de développement

| Règle | État |
|-------|------|
| Django Web = source de vérité | Respecté (aucune logique métier Web modifiée) |
| Pas de suppression de fonctionnalité | Respecté (code mort seulement supprimé) |
| Pas de mocks / fausses données | Respecté (rating → 0 documenté, KPIs réels) |
| IDs patient = String en Flutter | Vérifié (pas de `.toInt()` sur les IDs patient) |
| Alertes persistantes NEW/ACK/RESOLVED | Corrigé + tests |
| KPIs réels calculés depuis la DB | Corrigé + tests |
| Protocole MQTT réutilisé (même payload) | Confirmé + documenté (`docs/MQTT_PROTOCOL.md`) |
| Simulateur = même payload que le vrai Pi | Confirmé (`_source`, clés identiques) |
| Hardware-ready, pas de secrets en dur | Confirmé (`.env.example`, variables d'env) |
| Pas de seuils médicaux inventés | Seuils du projet conservés (`check_thresholds`, `SEUILS_DEFAUT`) |
| Validation après chaque groupe | Fait (check/test Django + analyze/test Flutter) |

## E. Environnement de validation

| Composant | Version / état |
|-----------|----------------|
| Python (système) | 3.11.9 — Django 5.2.17 |
| venv | Django 5.2.17 (maj depuis 3.1.12) — tous les tests OK |
| SQLite | `db.sqlite3` (mono-base effective ; `MongoRouter` force `default`) |
| Mosquitto | Running sur :1883 |
| Django runserver | 127.0.0.1:8000 (relancé, code à jour) |
| Flutter Web | build OK ; servi sur 127.0.0.1:8080 |
| server.py (IA) | importable + runtime vérifié (fallback étiqueté) |

## F. État des tests

- `manage.py test` : **31/31 OK** (venv et système). Nouveaux tests :
  persistance ack/resolve, filtres de statut, KPIs réels (dashboard/nurses), rating non
  fabriqué.
- `flutter analyze` : **0 issue**.
- `flutter test` : **19/19 OK**.
- Runtime : login→logout, 8 endpoints authentifiés 200, push HTTP 200, MQTT→DB→alertes,
  ack→resolve→filtres, 404 JSON sessions, build web OK.

## G. Points d'action restants (utilisateur)

1. **Régénérer le mot de passe d'application Gmail** (`xnii qhqd arku qvuc` a été exposé)
   et le mettre dans `.env` (`EMAIL_HOST_PASSWORD`).
2. Créer `.env` depuis `.env.example` et y placer `DJANGO_SECRET_KEY` (production :
   `DJANGO_DEBUG=False`).
3. Créer un compte admin manuellement si le mot de passe actuel de `admin` est perdu :
   `python manage.py shell -c "from accounts.models import User; u=User.objects.get(username='admin'); u.set_password('...'); u.save()"`.
4. Matériel : définir `RASPI_ID`/`MACHINE_ID`/broker MQTT dans `.env` sur le Raspberry Pi ;
   démarrer `edge_client.py` (simulation) ou `producer.py` (caméra réelle) et
   `server.py` avec `HF_TOKEN`.
5. Corriger la valeur corrompue `patient 11 type_de_dialyse = "H??modialyse"` en base
   (artefact d'un ancien payload PowerShell) via l'interface d'édition du patient.

## Synthèse des scores Phase 2

| Domaine | Avant | Après |
|---------|-------|-------|
| Backend / API | 85–90 | ~95 (KPIs réels, alertes persistantes, 404 JSON) |
| Flutter | 88 | ~95 (architecture devices complète, 0 issue) |
| Base de données | 90 | ~95 (rôles uniques, migrations cohérentes) |
| Sécurité | 35 | ~85 (secrets en env, mots de passe `secrets`, DEBUG env) |
| Testing | 60 | ~85 (31 tests Django dont 6 nouveaux, 19 Flutter) |
| Pipeline MQTT/IA | — | Vérifié runtime (simulateur→DB→alertes ; IA fallback étiqueté) |