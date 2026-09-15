# Rapport d'audit et correction — Flux temps réel PFA-Dialyse (Phase 3)

## FIXED
- `/api/real-monitoring/` (endpoint consommé par `dashboard.html` ET `surveillance.html`) renvoie maintenant le contrat attendu par le Web :
  - alias par mesure : `Qb` (=Debit_sang), `UF` (=Volume_UF), `status` (CRITICAL/WARNING/NORMAL) + `patient` réel ;
  - `alerts` **top-level** fusionnées (monitoring.Alerte + seances.Alert), niveaux normalisés HIGH/MEDIUM/LOW, avec `id`, `message`, `status`, `machine`, `time`.
- `monitoring/templates/surveillance.html` : patient pris du payload (`m.patient`) au lieu du "Patient test" codé en dur ; URLs ACK/RESOLVE pointées vers `/api/alerts/{id}/ack/` et `/api/alerts/{id}/resolve/` (routes Web `/monitoring/alert/...` supprimées en Phase 2 → boutons morts).
- `monitoring/templates/dashboard.html` : check niveau `alert.niveau === "RED"` → `"HIGH"` (les Alertes sont normalisées HIGH/MEDIUM/LOW).
- `monitoring/templates/alerts_history.html` : fonction `ackAlert` manquante ajoutée + URL resolve corrigée vers `/api/alerts/{id}/resolve/` ; `monitoring/views.alerts_history` normalise RED→HIGH / YELLOW→MEDIUM pour les badges.
- `/api/monitoring/live/` (surveillance Flutter) : inclut désormais **toutes** les séances actives même sans mesure (`Debit_sang` etc. à `null`), et fusionne les alertes `seances.Alert` (HIGH/MEDIUM) avec `monitoring.Alerte` (RED/YELLOW→HIGH/MEDIUM) — auparavant seules les `Alerte` apparaissaient.
- `mobile/lib/features/dashboard/.../dashboard_provider.dart` : ajout d'un **polling 5s** (comme Monitoring/Surveillance) ; les KPIs (séances actives, machines dispo…) se rafraîchissent en direct.
- `mobile/lib/features/surveillance/.../live_monitoring_entity.dart` : inchangé — `isHigh`/`isMedium` géraient déjà RED/HIGH et YELLOW/MEDIUM, cohérent avec la normalisation.

## ROOT CAUSES
1. **Contrat API/Web divergent sur `real_monitoring`** : le JS attend `m.Qb`, `m.UF`, `m.status`, `data.alerts` (top-level) ; l'API renvoyait `Debit_sang`, `Taux_UF`, `Volume_UF` et des alertes imbriquées par mesure. → Web dashboard/surveillance ne montraient jamais de valeurs ("--") ni d'alertes.
2. **URLs Web ACK/RESOLVE mortes** : `surveillance.html` et `alerts_history.html` postaient vers `/monitoring/alert/{id}/ack/` et `/resolve/`, routes inexistantes depuis le nettoyage Phase 2 (les vues `monitoring.views.ack_alert/resolve_alert` avaient été supprimées).
3. **`patient` codé en dur** dans `surveillance.html` (« Patient test ») — aucune donnée réelle affichée.
4. **`api_monitoring_live` filtré par `if last:`** : une séance « en cours » sans première mesure était invisible côté mobile ; et seules `Alerte` (RED/YELLOW) remontaient, jamais `seances.Alert` (HIGH/MEDIUM).
5. **Deux conventions de niveau** : `Alerte` = RED/YELLOW vs `seances.Alert` = HIGH/MEDIUM ; dashboard.html testait "RED", surveillance.html testait "HIGH"/"MEDIUM" → incoherence d'affichage.
6. **Dashboard Flutter sans polling** : `DashboardNotifier` ne chargeait qu'une fois ; les KPIs ne reflétaient pas le démarrage d'une séance.

## DATA FLOW (vérifié en runtime)
Raspberry Pi/MQTT (`dialysis/machine/{machine_id}`) → `mqtt_listener.py` (ou HTTP `POST /api/push/`) → `LiveMeasurement` en base + `check_thresholds` (monitoring.Alerte RED/YELLOW) + `analyser_mesure` (seances.Alert HIGH/MEDIUM) → mêmes données servies par `/api/real-monitoring/` (Web), `/api/monitoring/live/` (Flutter surveillance), `/api/monitoring/` (Flutter monitoring), `/api/alerts/` (historique) → Web dashboard/surveillance polling 3s, Flutter dashboard 5s, monitoring 5s, surveillance 3s → ACK/RESOLVE persistés via `/api/alerts/{id}/ack|resolve/` → rapport de fin de séance.

## VERIFIED (acceptance runtime, données réelles)
- 31 tests Django OK (`manage.py test`), `manage.py check` OK ; `flutter analyze` 0 issue ; `flutter test` 19 OK ; `flutter build web` OK.
- Serveurs : runserver venv :8000 + http.server (Flutter web) :8080 → 200 ; Mosquitto :1883 actif.
- Flux réel HTTP : login → création séance → `start` → `POST /api/push/` (Qb=180) → mesure en base, `monitoring_alerts_created:1`, alerte HIGH « Débit sanguin faible » visible dans `real-monitoring` (top-level) et `monitoring/live`.
- ACK → RESOLVE → `status` persisté (NEW→ACK→RESOLVED) ; les alertes RESOLVED disparaissent du live (filtre `status="NEW"`).
- Séance « en cours » **sans mesure** : présente dans `/api/monitoring/live/` (Debit_sang=null) — fix validé.
- Flux réel MQTT : `paho` → topic `dialysis/machine/123` → `mqtt_listener.py` → `LiveMeasurement` (Qb=210, UF_vol=950) visible dans le live API ; message ignoré correctement quand aucune séance active.
- Pages Web rendues authentifiées (dashboard, surveillance, alerts-history, seances-history) ; les 4 corrections HTML vérifiées dans le rendu (patient payload, URLs `/api/alerts/`, niveau HIGH, fonction ackAlert présente).
- KPIs `/api/dashboard/` : active_sessions 0→2→0, machines Prete libérées à la fin de séance.

## NOT PHYSICALLY VERIFIED
- Aucun vrai Raspberry Pi/dialyseur raccordé ; le flux MQTT a été validé avec un client `paho-mqtt` local simulant le payload exact du protocole (mêmes clés `machine_id/Qb/UF_rate/PA/PTM/PV/UF_volume/Heparin`). Branchement matériel + timestamps MQTT réels non testés.
- Sonnerie audio (`sounds/alert.mp3`) et popups navigateur non testés sur navigateur réel.

## REMAINING
- `surveillance.html` ne construit qu'**une** carte de session depuis `data.measurements[0]` (design historique) : si plusieurs machines sont actives simultanément, une seule carte s'affiche. Les KPIs comptent `sessions.length` → sous-compte multi-machines. Non corrigé (hors périmètre « flux cassé »), à traiter si multi-postes requis.
- `real_monitoring` reste **public** (pas de `@api_login_required`) — délibéré pour le polling Web sans header, à réévaluer si exposition hors LAN.
- Patient 11 conserve des données héritées corrompues (`H??modialyse`) signalées en Phase 2 ; machine M001 en « Prete » après nettoyage.

## FILES CHANGED
- `api/views.py` — `real_monitoring`, `api_monitoring_live` réécrits + helpers `_normalize_level`, `_live_alerts`.
- `monitoring/templates/surveillance.html` — patient réel + URLs ACK/RESOLVE `/api/alerts/`.
- `monitoring/templates/dashboard.html` — check niveau "HIGH" (au lieu de "RED").
- `monitoring/templates/alerts_history.html` — `ackAlert` ajouté + URL resolve `/api/alerts/`.
- `monitoring/views.py` — normalisation RED/YELLOW→HIGH/MEDIUM dans `alerts_history`.
- `mobile/lib/features/dashboard/presentation/providers/dashboard_provider.dart` — polling 5s.

## COMMANDS
- `.\venv\Scripts\python.exe -X utf8 manage.py check`
- `.\venv\Scripts\python.exe -X utf8 manage.py test`
- `flutter analyze` / `flutter test` / `flutter build web` (dans `mobile/`)
- `.\venv\Scripts\python.exe -X utf8 manage.py runserver 127.0.0.1:8000 --noreload`
- `.\venv\Scripts\python.exe -X utf8 -m http.server 8080 --bind 127.0.0.1` (depuis `mobile/build/web`)
- `.\venv\Scripts\python.exe -X utf8 mqtt_listener.py`