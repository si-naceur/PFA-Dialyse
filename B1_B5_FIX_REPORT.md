# Rapport de correction — B1 à B5 (PFA-Dialyse)

Date : 17/08/2026
Portée : uniquement les constats B1–B5 de `QA_AUDIT_REPORT.md`. B6–B8 NON modifiés. Aucun nettoyage effectué. Aucun commit/push.

---

## 1. Fichiers modifiés (7)

| Fichier | Constat | Changement |
|---|---|---|
| `accounts/views.py` | B1, B3 | Ajout de `@app_login_required` + `@role_required` sur `ajout_infirmier` et `add_doctor` ; `@app_login_required` + `current_user` sur `dashboard` |
| `accounts/templates/password_reset_confirm.html` | B2 | Ligne 35 : `{% url 'login' %}` → `{% url 'accounts:login_view' %}` |
| `seances/views.py` | B4 | GET `create_session` : `render('createSession.html')` → `redirect("seances:planning")` |
| `seances/templates/planning.html` | B5 | Bouton « Nouvelle séance » conditionné Admin/Docteur + JS null-safe sur `newSessionBtn` |
| `accounts/tests.py` | Tests | Réécrit : `AccountCreationAuthorizationTests`, `DashboardAuthorizationTests`, `PasswordResetTests` |
| `seances/tests.py` | Tests | Ajout de `CreateSessionPageTests` (B4/B5) |
| `api/tests.py` | Tests | Ajout de `test_session_create_api_nurse_forbidden` + `test_session_create_api_anonymous_forbidden` |

---

## 2. Détail des modifications

### B1 — Création de comptes non protégée
`accounts/views.py` :
- `add_doctor` : `@app_login_required` + `@role_required("Admin", redirect_to="accounts:error")` (avant : aucune protection).
- `ajout_infirmier` : `@app_login_required` + `@role_required("Admin", "Docteur", redirect_to="accounts:error")` (avant : aucune protection).

### B2 — Lien « Retour à la connexion » 500 sur la page de reset
`password_reset_confirm.html` ligne 35 : `{% url 'login' %}` (name inexistant → NoReverseMatch → 500) → `{% url 'accounts:login_view' %}` (existe, ligne 77 inchangée).

### B3 — `/dashboard/` accessible sans connexion
`accounts/views.py` `dashboard` : ajout de `@app_login_required` et passage de `current_user` dans le contexte (le template `base.html` le requiert).

### B4 — Page « Nouvelle séance » obsolète
`seances/views.py` `create_session` GET : `render('createSession.html')` → `redirect("seances:planning")`. Le flux POST (AJAX modal du planning, canonical) est inchangé.

### B5 — Infirmiers peuvent voir le bouton de création de séance
Découverte clé : le backend web `create_session` possédait DÉJÀ `@role_required("Admin", "Docteur")` (seances/views.py:92-93) → backend déjà unifié avec l'API. Le seul écart réel était l'interface : le bouton était affiché pour tous les rôles.
- `planning.html` : bouton entouré de `{% if current_user.role.name == "Admin" or current_user.role.name == "Docteur" %}...{% endif %}`.
- JS : `const newSessionBtn = document.getElementById('newSessionBtn'); if (newSessionBtn) { ... }` (évite une erreur JS quand le bouton est absent).

Correction par rapport à l'audit initial : l'affirmation « les infirmiers peuvent créer des séances via le web » était fausse — le backend était déjà verrouillé ; seul le bouton UI posait problème.

---

## 3. Tests ajoutés

### `accounts/tests.py`
- `AccountCreationAuthorizationTests` (9 tests) : anon bloqué sur `add-doctor`/`nurses/ajouter` ; infirmier & docteur bloqués sur `add-doctor` (`/error/`) ; admin crée docteur ; infirmier bloqué sur `ajout_infirmier` (`/error/`) ; docteur & admin créent infirmier.
- `DashboardAuthorizationTests` (2 tests) : anon → 302 vers `/` ; authentifié → 200.
- `PasswordResetTests` (5 tests) : token valide → formulaire ; reset valide change le mot de passe (`check_password`) ; token invalide → 200 « Lien invalide ou expiré » (pas de 500) ; token réutilisé (via `used_at`) → 200 ; token expiré (TimestampSigner avec timestamp −7200s) → 200.

### `seances/tests.py` — `CreateSessionPageTests` (7 tests)
- GET `create_session` → 302 `/seances/` (B4).
- Infirmier → POST 302 `/error/`, aucune séance créée ; Docteur/Admin → 200 + séance créée ; anon → 302, rien créé (B5).
- Bouton `newSessionBtn` masqué pour infirmier, présent pour admin.

### `api/tests.py` (2 tests)
- Infirmier → POST `/api/sessions/` → 403, aucune séance ; anon → 401.

---

## 4. Résultats de vérification

### Django
- `python manage.py check` → System check identified no issues.
- `python manage.py test api seances monitoring accounts` → **Ran 58 tests, OK** (0 échec).

### Flutter (`mobile/`)
- `flutter analyze` → No issues found.
- `flutter test` → **21 tests passed**.
- `flutter build web` → Built `build\web` (avertissements wasm préexistants, sans impact).

### Smoke tests runtime (serveur redémarré pour recharger le code, PID 4144/21372)
- Anon `/dashboard/` → 302 `/` (B3 ✓) ; anon `/add-doctor/`, `/nurses/ajouter/` → 302 `/` (B1 ✓) ; anon `/seances/create_session/` → 302 `/` (B4 ✓).
- B1 : infirmier `add-doctor` GET → `/error/` ; docteur `add-doctor` → `/error/` ; docteur/admin `ajout_infirmier` → `/nurses/` (redirection liste = comportement existant du GET, inchangé).
- B4/B5 : infirmier POST `create_session` → 302 `/error/` ; docteur & admin POST → 200 `{"success": true, "id": ...}`.
- B2 : token invalide → 200 page « Lien invalide ou expiré » + lien de connexion corrigé ; token expiré → 200 ; premier usage POST → 302 `/` ; réutilisation du token → 200 « Lien invalide ou expiré ». (Mot de passe de `qa_nurse_test` modifié pendant le test : désormais `NewPass12345!`.)
- B5 UI : planning infirmier sans bouton, planning admin avec bouton.

### Régression cycle de vie (comportement existant préservé)
Session `a89e347e` : CREATE (planifiée) → `/pre/` START (en cours, mesures pré-séance 70.5/120-80/72 enregistrées) → visible dans `/api/monitoring/live/` → page surveillance 200 → POST `/post/` → **terminée**, machine M001 repassée `Prete`, rapport généré. Garde machine : 2e séance sur M001 (`841e6c4a`) bloquée, restée `planifiée`.

---

## 5. Diagnostic de connexion API (« Cannot connect to API »)

### État au moment du diagnostic
- **Django était bien en cours d'exécution** : le serveur répondait sur `http://127.0.0.1:8000`.
- **Propriétaire du port 8000** : PID `21372` (enfant de `4144`), lancé via `manage.py runserver 127.0.0.1:8000 --noreload`.
- **`manage.py check`** : System check identified no issues.
- **Réponse HTTP** : `/` → 200 ; `/dashboard/` → 302 `/` ; `/api/machines/` → 401 (attendu) ; `/seances/` → 302 `/` ; CORS préflight depuis `http://127.0.0.1:8080` → 200 avec `Access-Control-Allow-Origin` correct.

### Cause exacte de l'échec de connexion
- Le port 8000 n'était écouté **qu'en IPv4** (`127.0.0.1:8000`, socket `AF_INET`).
- L'application Flutter Web était servie par `http.server` sur le port 8080 (PID `6112`/`19896`), qui écoute en `0.0.0.0` ET `[::]`.
- Le navigateur ouvrait l'appli via `http://localhost:8080`. Sur cette machine, `localhost` se résout en **`::1` d'abord**, puis `127.0.0.1` (ordre `::1`, `127.0.0.1` — vérifié par `GetHostAddresses`).
- `ApiEndpoints.baseUrl` (Flutter, `api_endpoints.dart:9-19`) dérive l'URL de l'API de l'hôte de la page : sur `localhost:8080` il génère `http://localhost:8000`.
- Le navigateur résout alors `http://localhost:8000` vers `::1` (IPv6), tente `[::1]:8000` → **refus de connexion** (`WinError 10061`), d'où « Cannot connect to API ». Les helpers Python de smoke test (`browser_client.py`, `web_client.py`) utilisent `127.0.0.1:8000` (IPv4) → ils fonctionnaient ; seul le chemin navigateur IPv6 échouait.

### Correction apportée (aucun code applicatif modifié)
- Un second `runserver` a été lancé en écoute **IPv6** `[::1]:8000 --noreload` (PID `10068` / enfant `15224`), en parallèle du serveur IPv4 existant.
- Vérifications après correction :
  - `127.0.0.1:8000` → CONNECT OK ; `[::1]:8000` → CONNECT OK ; `localhost:8000` → CONNECT OK.
  - `GET http://localhost:8000/api/machines/` (chemin emprunté par le navigateur) → 401 (réponse normale sans auth).
  - Login `POST /api/login/` via le chemin IPv6/localhost → 200 `success: true` ; `/api/monitoring/live/` et `/api/dashboard/` → 200.
- Note : un `GET [::1]:8000` direct avec `Host: [::1]:8000` renvoie 400 (Host non autorisé) ; avec l'en-tête `Host: localhost:8000` réellement envoyé par le navigateur, tout répond correctement. Ce n'est pas un bug applicatif.

### Résultat
- **Les smoke tests runtime peuvent continuer** : le chemin navigateur (IPv6/localhost) et le chemin Python (IPv4/127.0.0.1) aboutissent tous deux.
- Tous les smoke tests B1–B5 précédemment échoués repassent : voir section 4.

---

## 6. Points résiduels B1–B5
- Aucun problème fonctionnel restant constaté sur B1–B5.
- Note d'environnement (hors code) : Django n'écoutait qu'en IPv4. La connexion « Cannot connect to API » était due à un mismatch IPv6/IPv4 `localhost`, corrigé en ajoutant un listener `[::1]:8000`. Pour éviter toute réapparition, ouvrir l'appli web via `http://127.0.0.1:8080` ou garantir que Django écoute sur les deux piles.

---

## 6. Garanties
- **B6–B8 NON modifiés** : aucun changement dans `settings.py` (cookies sécurisés/HTTP login), `accounts/models.py` (hash pbkdf2-only), ni correction des machines doublement réservées (123 ×2, M200 ×2 en cours — constat préexistant).
- **Aucun nettoyage** : utilisateurs de test (anon_nurse_x/anon_doctor_x/qa_nurse_test/qa_doctor_test/qa_admin_test/api_test_admin/api_test_doctor/api_test_admin2) et séances de test (y compris `50b76cef`, `ce137cf0`, `015c4361`, `a89e347e`, `841e6c4a`, `015c4361`) laissés en base.
- Autres fichiers sales du working tree (`mqtt_*.py`, `producer.py`, `server.py`, `edge_client.py`, `machines/signals.py`, templates supprimés, `db.sqlite3`) : modifications PRÉEXISTANTES, non issues de cette tâche.
- Aucun commit, aucun push, aucun reset effectué.