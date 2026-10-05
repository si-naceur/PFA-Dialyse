# AUDIT COMPLET — Projet PFA-Dialyse

Ce document présente l'audit exhaustif du projet **PFA-Dialyse**, réalisé en comparant les exigences fonctionnelles et techniques du rapport de PFA (`Rapport_PFA.pdf` & `Product_Backlog.pdf.pdf`) avec le code source actuellement présent dans le repository.

---

## Tableau de Synthèse de l'Audit

| Fonctionnalité | Présente ? | Fonctionnelle ? | Fichiers concernés | Problèmes identifiés | Action nécessaire | Priorité |
| :--- | :---: | :---: | :--- | :--- | :--- | :---: |
| **1. Service IA OCR (Qwen2.5-VL)** | Oui | Partielle | `qwen_api.py`, `server.py`, `qwen_direct_test.py` | `qwen_api.py` manque de gestion d'erreur robuste (timeout, Ollama down/HTTP 500, parsing JSON incomplet). Risque d'inversion PA/PV si le prompt n'est pas strictement encadré. | Renforcer `qwen_api.py` (gestion d'erreurs HTTP/Ollama propre, parsing JSON sécurisé, garanties PA/PV, retours `null` propres). | **Haute** |
| **2. Pipeline MQTT & Ingestion Image** | Oui | Partielle | `mqtt_listener.py`, `edge_client.py`, `producer.py` | `mqtt_listener.py` attend un payload JSON pré-extrait au lieu d'accepter et traiter les images transmises sur `dialysis/machine/{machine_id}/image` via le pipeline IA. | Mettre à jour `mqtt_listener.py` pour supporter la réception d'images JPEG/base64, appeler le service IA, valider et sauvegarder dans Django. | **Haute** |
| **3. Validation des Données (Clean Layer)** | Non | Non | `monitoring/alerte.py`, `api/views.py` | Pas de module centralisé de validation stricte post-IA. Les valeurs nulles, hors bornes physiques ou aberrantes ne sont pas formellement filtrées avant sauvegarde. | Implémenter un service `validate_measurements()` (vérification des types, bornes physiques, non-inversion PA/PV, préservation des `null` sans invention de données). | **Haute** |
| **4. Modèles Django & Ingestion DB** | Oui | Partielle | `monitoring/models.py`, `seances/models.py` | Duplication des modèles d'alertes (`monitoring.Alerte` vs `seances.Alert`) et de mesures (`LiveMeasurement` vs `VitalReading`). | Unifier la persistance des mesures dans `LiveMeasurement` et des alertes dans `seances.Alert` pour assurer une cohérence totale dans toute l'application. | **Haute** |
| **5. Détection des Alertes & Seuils** | Oui | Partielle | `monitoring/alerte.py`, `monitoring/services.py` | `monitoring/services.py` utilise des seuils en dur différents de `seances.Seance` et de `monitoring/alerte.py`. | Harmoniser la logique d'alerte avec les seuils configurés sur la séance en cours ou par défaut selon le rapport clinique. | **Haute** |
| **6. Cooldown des Alertes (15 min)** | Non | Non | `monitoring/alerte.py`, `seances/models.py` | Aucun mécanisme de déduplication/cooldown de 15 minutes par machine et par paramètre n'est implémenté. Les alertes se répètent à chaque mesure. | Implémenter le cooldown de 15 minutes par machine et par paramètre d'alerte. | **Haute** |
| **7. Intégration n8n & Risque Critique** | Non | Non | `api/views.py`, `monitoring/ai_service.py` | Endpoint d'alerte critique / trigger webhook n8n incomplet ou absent. Pas de vérification `ready` ni d'envoi du payload enrichi. | Créer l'intégration webhook n8n pour le déclenchement des alertes critiques avec payload complet (score, prédiction, tendance, action recommandée). | **Haute** |
| **8. Endpoint Résumé de Séance (`/api/agent/resume-seance/`)** | Non | Non | `api/urls.py`, `api/views.py`, `seances/views.py` | L'endpoint `/api/agent/resume-seance/` spécifié dans le rapport n'existe pas dans l'application Django. | Implémenter l'endpoint `/api/agent/resume-seance/` (agrégation des `LiveMeasurement`, statistiques min/max/moyenne, calcul des alertes, appel LLM et retour JSON structuré). | **Haute** |
| **9. Rapport de Séance (`RapportSeance`)** | Oui | Partielle | `patients/templates/rapport_seance.html`, `patients/views.py`, `seances/models.py` | Le modèle `RapportSeance` et le template HTML existent, mais la génération automatique du rapport complet lors de la clôture de séance n'est pas liée au résumé IA. | Connecter la fin de séance à la génération automatique du HTML de rapport via le résumé IA et l'enregistrer dans `RapportSeance`. | **Haute** |
| **10. Dashboard Web (Live, Historique, Séance)** | Oui | Partielle | `monitoring/templates/dashboard.html`, `surveillance.html`, `seances_history.html` | Le dashboard affiche une interface statique/partielle sans rafraîchissement automatique fluide des dernières mesures live, graphiques temporels et indicateurs de séance. | Connecter le dashboard à l'API live (`/api/monitoring/live/`), afficher les courbes (Qb, PA, PV, PTM, UF), les cartes de statut et l'historique de séance. | **Moyenne** |
| **11. Machine Status & Heartbeat** | Oui | Partielle | `machines/views.py`, `machines/models.py` | Le heartbeat de Raspberry Pi existe (`/machines/raspi/heartbeat/`), mais l'état `online`/`offline` n'est pas répercuté dynamiquement sur le dashboard. | Mettre à jour l'état de la machine en fonction de la fraîcheur du dernier heartbeat / de la dernière mesure reçue. | **Moyenne** |
| **12. Application Mobile Flutter** | Oui | Partielle | `mobile/` | Le code Flutter existe (auth, dashboard pages) mais nécessite une validation de la communication avec les API Django. | Vérifier et corriger les endpoints d'authentification et de consultation des alertes/mesures dans l'application mobile. | **Moyenne** |
| **13. Endpoint SuperAdmin Chat (`/api/agent/superadmin/`)** | Non | Non | `api/urls.py`, `api/views.py` | L'endpoint n8n ReAct agent SuperAdmin mentionné au Chapitre 6 du rapport est absent. | Implémenter l'endpoint `/api/agent/superadmin/` avec boucle ReAct et enregistrement dans `ConversationLog`. | **Basse** |
| **14. Robustesse, Logs & Startup Scripts** | Non | Partielle | `manage.py`, `mqtt_listener.py`, `edge_client.py` | Absence de logs structurés uniformes et de script de lancement global simple du pipeline. | Ajouter un logging applicatif uniforme (`[MQTT]`, `[AI]`, `[VALIDATION]`, `[DB]`, `[ALERT]`, `[N8N]`) et documenter/créer la procédure de démarrage. | **Moyenne** |

---

## Détail des Constats par Composant

### 1. Backend Django & Modèles de Données
- **Existence** : Apps Django `accounts`, `api`, `machines`, `monitoring`, `patients`, `seances`.
- **Modèles de Mesures** : Deux modèles concurrents existent : `monitoring.LiveMeasurement` et `monitoring.VitalReading`. `LiveMeasurement` est préférentiellement lié à `Seance` et utilisé par les vues de monitoring.
- **Modèles d'Alertes** : `seances.Alert` contient les champs normés (`alert_type`, `message`, `danger_level` LOW/MEDIUM/HIGH, `recommended_action`), alors que `monitoring.Alerte` contient (`niveau` RED/YELLOW, `status`, `message`).
- **Seuils** : Le modèle `Seance` définit déjà tous les seuils configurables par séance (`blood_flow_min/max`, `arterial_pressure_min/max`, etc.).

### 2. Service IA/OCR (Qwen)
- `qwen_api.py` est une application FastAPI légère interfaçant Ollama (`qwen2.5vl:3b`).
- **Erreurs relevées** : En cas de défaillance d'Ollama ou d'image floue/illisible, la fonction n'intercepte pas correctement les exceptions réseau ou renvoie un dictionnaire incomplet. Le prompt doit être strict sur le non-croisement entre PA (artérielle, négative) et PV (veineuse, positive).

### 3. Pipeline MQTT & Edge Client
- `mqtt_listener.py` s'abonne à `dialysis/machine/#`. Il reçoit des données JSON simulées.
- **Incohérence** : Selon la spécification (Section 3), le pipeline doit accepter le topic `dialysis/machine/{machine_id}/image` contenant l'image JPEG envoyée par le Raspberry Pi, appeler l'IA, valider le JSON extrait et l'enregistrer dans Django.

### 4. Alertes, Cooldown & n8n
- Le rapport clinique spécifie un **cooldown de 15 minutes** par machine et par paramètre pour éviter l'inondation de notifications. Ce mécanisme est absent dans le code actuel.
- Les workflows n8n nécessitent deux endpoints REST clés :
  1. `POST /api/agent/resume-seance/` pour la génération automatique du résumé de fin de séance par LLM.
  2. `POST /api/agent/superadmin/` pour l'agent conversationnel ReAct.

### 5. Rapport de Séance & Dashboard Live
- `patients/templates/rapport_seance.html` est prêt visuellement.
- Le modèle `RapportSeance` est relié à `Seance`.
- Le lien automatique entre la cloture de séance (`status='terminée'`), la génération du résumé IA et la sauvegarde de `RapportSeance` doit être finalisé.

---

## Plan d'Action pour la Suite du Projet

Conformément à la directive d'exécution globale, le travail sera réalisé étape par étape sans casser le code existant :

1. **PHASE 2 : Pipeline Image → AI** (`qwen_api.py` & `mqtt_listener.py`).
2. **PHASE 3 : AI → Validation → Django** (couche de validation stricte, persistance DB).
3. **PHASE 4 : Django → Dashboard** (API live, actualisation temps réel, graphiques).
4. **PHASE 5 : Alertes & Cooldown** (gestion des seuils de la séance + cooldown de 15 minutes).
5. **PHASE 6 : n8n & Notifications** (intégration webhook & notification des risques critiques).
6. **PHASE 7 : Résumé Automatique de Fin de Séance** (`/api/agent/resume-seance/`).
7. **PHASE 8 : Rapport de Séance** (génération HTML/PDF `RapportSeance`).
8. **PHASE 9 : Flutter** (vérification et adaptation API mobile).
9. **PHASE 10 : Tests End-to-End & Robustesse**.
10. **PHASE 11 : Documentation & Startup Scripts** (`IMPLEMENTATION_STATUS.md`).
