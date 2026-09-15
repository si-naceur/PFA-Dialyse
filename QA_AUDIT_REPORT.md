# PFA-Dialyse — FULL END-TO-END QA AUDIT REPORT
Date: 2026-08-17
Auditor: opencode QA audit session (read-only + runtime tests)
Scope: Session lifecycle, page consistency, live monitoring, machine integrity,
       authentication, authorization, Flutter web, Django checks/tests.
NOTE: No code was modified. All lifecycle changes were performed through the
normal application flows on test sessions. Pre-existing database rows were not altered.

====================================================
1. EXECUTIVE SUMMARY
====================================================
Verdict: **PASS WITH ISSUES**

The core dialysis workflow is fully functional and consistent:
CREATE -> START -> LIVE -> END -> CANCEL all work correctly through both the
web UI and the API. Double-booking is prevented (API 409 + web redirect with
message). Live monitoring streams measurements and alerts correctly to both
the web surveillance page and the Flutter mobile API. Role-based access is
correctly enforced across the web UI and the API. All 34 Django tests pass,
flutter analyze is clean, all 21 Flutter tests pass, and `flutter build web`
succeeds.

However, the audit found **1 CRITICAL security issue** (unauthenticated account
creation), **1 HIGH bug** (password-reset token reuse causes HTTP 500), several
MEDIUM issues, and a few LOW/observation items detailed below.

----------------------------------------------------
2. SESSION LIFECYCLE
----------------------------------------------------
Test session used: c9f05db6-eead-4996-91d2-409348a008c1 (M001, patient Sami Ben Ali)
Created via the real web planning modal AJAX (POST /seances/create_session/).

STEP      | RESULT | DETAILS
----------|--------|-----------------------------------------------------------
CREATE    | PASS   | New session created, status "planifiée", appears on
          |        | planning page. Machine stays "Prete". API detail shows
          |        | patient, machine, date/time, duration, notes, debit,
          |        | default thresholds, pre_measurements=null.
START     | PASS   | Web pre_session_page POST -> 302 to planning. Status
          |        | becomes "en cours", machine becomes "Reserve", machine
          |        | sessions+1 & hours+duration (M001: 2->3 sessions, 12.0h),
          |        | pre-measurements recorded, thresholds saved.
LIVE      | PASS   | Demo simulator (DEMO_MODE=true) fed LiveMeasurements.
          |        | /api/monitoring/live/ shows session with current PA/Qb/UF;
          |        | /api/real-monitoring/ feeds the surveillance page;
          |        | alert stream active. Dashboard KPIs updated.
END       | PASS   | Web post_session_page POST -> 302. Status "terminée",
          |        | machine back to "Prete", post-measurements recorded,
          |        | rapport generated (Rapport page renders full content).
CANCEL    | PASS   | Web cancel endpoint -> 200. Status "annulée". Second
          |        | cancel -> 400 ("Seules les séances planifiées...").
          |        | Pre page on cancelled session -> redirect (blocked).

Double-booking test (session 2e9f2c86 on occupied M200):
- API start: 409 "Machine déjà occupée par une séance en cours", stays planifiée.
- Web pre POST: 302 -> planning with error message, stays planifiée.

NOTE: The DB already contains double-booked machines from before this audit
(123 has two "en cours" sessions, M200 has two "en cours"). The guard prevents
NEW double-bookings but does not repair existing data. Recommend a data-cleanup.

----------------------------------------------------
3. PAGE-BY-PAGE RESULTS (web)
----------------------------------------------------
PAGE                        | STATUS | STATE-LINK | NOTES
----------------------------|--------|------------|------------------------------------
/ (login)                   | 200    | -          | Correct form + reset form
/seances/ (planning)        | 200    | shows all  | Shows planifiée/en cours/terminée
/seances/create_session/    | 200    | EMPTY      | DEAD TEMPLATE - no form at all
/seances/<id>/pre/          | 200    | only planned| Blocked for cancelled (302)
/seances/<id>/post/         | 200    | only en cours| Redirects to planning otherwise
/patients/ (list)           | 200    | -          |
/patients/add/              | 302    | -          | POST-only (redirect on GET)
/patients/profile/11/       | 200    | -          | Full profile rendered
/patients/<seance>/detail/  | 200    | rapport    | Rapport for terminated session
/machines/                  | 200    | -          | Admin/Infirmier only (Doctor: 302 error)
/machines/ajout_machine/    | 302    | -          | POST-only
/machines/configurer/1/     | 200    | -          |
/machines/details/1/        | 200    | -          | Shows active_session when en cours
/machines/raspi/            | 200    | -          | Sidebar Admin-only; backend allows 3 roles
/dashboard/                 | 200    | -          | **NO AUTH DECORATOR - anonymous access**
/monitoring/ (dash)         | 200    | -          | Admin only
/monitoring/surveillance/   | 200    | live feed  | JS fetch /api/real-monitoring/
/monitoring/alerts-history/ | 200    | -          |
/monitoring/seances-history/| 200    | -          |
/docteurs/                  | 200    | -          | Admin only
/nurses/                    | 200    | -          | Admin/Docteur
/profile/                   | 200    | -          | first-login gate enforced
/admin/                     | 302    | -          | Django admin (default login)

----------------------------------------------------
4. SURVEILLANCE
----------------------------------------------------
- Web surveillance page loads live data via /api/real-monitoring/ (setInterval).
- Flutter uses /api/monitoring/live/ (session-per-machine + alerts + last_update).
- Both endpoints returned correct live data during the test (5 active sessions,
  current PA/PTM/PV/UF/Débit, alerts with level + status).
- Status label logic (CRITICAL/WARNING/NORMAL) matches surveillance.html and the
  Flutter implementation.
Result: PASS

----------------------------------------------------
5. MACHINE INTEGRITY
----------------------------------------------------
- Start -> machine "Reserve" + session counts/hours incremented.
- End   -> machine "Prete" (freed).
- Double-booking guard present in both web pre_session_page and API start.
- Pre-existing DB anomaly: machines 123 and M200 each have TWO "en cours"
  sessions (data created before the guard). Not repaired by the app.
- /api/push/ (device endpoint) is unauthenticated; requires knowing machine_id.
Result: PASS (with pre-existing data anomaly to clean up)

----------------------------------------------------
6. AUTHENTICATION
----------------------------------------------------
Web:
- Login validates via check_password; disabled account rejected ("Ce compte est
  désactivé...").
- first_login=True forces redirect to /profile/ until password is changed
  (verified with test users); after change, access is unlocked.
- Logout flushes session + records UserActivity.
API (mobile):
- POST /api/login/ -> {success, sessionid, user}; wrong password/nonexistent
  user -> 401; anonymous API calls -> 401 "Authentication required";
  invalid session token -> 401; logout invalidates the session.
CRITICAL: **Both add_doctor and ajout_infirmier have NO @app_login_required /
@role_required decorator.** Verified: an anonymous client with a CSRF token can
POST /add-doctor/ and /nurses/ajouter/ and successfully create Docteur /
Infirmier accounts (test users anon_doctor_x, anon_nurse_x created). Any
anonymous visitor can therefore provision staff accounts.
MEDIUM: accounts.views.dashboard (/dashboard/) has no auth decorator - any
anonymous visitor sees the user-activity table.
OBSERVATION: SESSION_COOKIE_SECURE=True / CSRF_COOKIE_SECURE=True set cookies
with the Secure flag. Plain-HTTP clients (requests, curl, Postman) refuse to
send them, so web login over http:// returns 403 CSRF failure. Chrome on
localhost masks this because browsers treat localhost as a secure context. Any
deployment serving plain HTTP (or non-browser clients) will fail login.
OBSERVATION: User.save() only recognizes hashes starting with "pbkdf2_"
(accounts/models.py:28). If PASSWORD_HASHERS were set to Argon2/bcrypt, every
save would re-hash the password (silent double-hashing). With default PBKDF2
this works.

----------------------------------------------------
7. DOCTOR / NURSE ACCOUNTS
----------------------------------------------------
- Web /nurses/ajouter/ and /add-doctor/ create accounts with auto-generated
  passwords, first_login=True, is_active=True. Verified working (and - per #6 -
  accessible to anonymous users - SECURITY BUG).
- API POST /api/nurses/ is correctly gated Admin/Docteur (403 for nurse).
- API GET /api/doctors/ correctly gated Admin (403 for nurse/doctor).
- First-login password change flow verified for nurse/doctor/admin test users.

----------------------------------------------------
8. AUTHORIZATION (role matrix, verified at runtime)
----------------------------------------------------
ROLE  | planning | machines | patients | surveill. | /dashboard/ | /monitoring/ | docteurs | nurses | raspi
------|----------|----------|----------|-----------|-------------|--------------|----------|--------|------
Admin | OK       | OK       | OK       | OK        | OK          | OK           | OK       | OK     | OK
Docteur| OK      | denied(OK)| OK      | OK        | OK          | denied(OK)   | denied(OK)| OK    | OK*
Infirmier|OK      | OK       | OK       | OK        | OK          | denied(OK)   | denied(OK)| denied(OK)| OK*
* raspi view backend allows Admin/Infirmier/Docteur but the sidebar only shows
  the link for Admin - minor UI/backend mismatch (access is broader than UI).
Machine list (machines:machines) intentionally excludes Docteur; the sidebar
also hides the link for Docteur - consistent.

API role enforcement (verified):
- GET /api/doctors/      -> Admin only (403 otherwise)           PASS
- POST /api/nurses/      -> Admin/Docteur (403 for nurse)        PASS
- POST /api/sessions/    -> Admin/Docteur only (403 for nurse)
  INCONSISTENCY: the web planning modal (seances/views.py create_session) has
  NO role gate, so a nurse CAN create a session via web but NOT via API.
  Recommend aligning both (allow Admin/Infirmier/Docteur on the API, or gate
  the web form).

----------------------------------------------------
9. FLUTTER
----------------------------------------------------
- flutter analyze  : No issues found.
- flutter test     : All 21 tests passed.
- flutter build web: SUCCESS ("Built build\web").
  Wasm dry-run warnings from flutter_secure_storage_web (dart:html) are
  pre-existing and do not affect the standard JS build.
- API contract mapping (verified by code exploration + runtime):
  all 23 API paths used by mobile match api/urls.py 1:1; login response
  contract, X-Session-Id header binding, session create/start/end/cancel
  payloads, patient age computed server-side, and live monitoring shape all
  match the backend.
Result: PASS

----------------------------------------------------
10. DJANGO
----------------------------------------------------
- python manage.py check  : 0 issues.
- python manage.py test api seances monitoring : 34/34 OK (28.4s).
Result: PASS

----------------------------------------------------
11. BUGS FOUND
----------------------------------------------------
ID | SEV  | Page/Feature       | Expected                     | Actual                          | Root cause (file:line)                                 | Recommended fix
---|------|--------------------|------------------------------|---------------------------------|--------------------------------------------------------|----------------------------------------
B1 |CRIT  | /add-doctor/, /nurses/ajouter/ | Only authenticated Admin/Docteur may create accounts | ANY anonymous visitor can create Docteur/Infirmier accounts (verified: anon_doctor_x, anon_nurse_x created) | accounts/views.py:317 (ajout_infirmier), :346 (add_doctor) - missing @app_login_required and @role_required | Add @app_login_required + @role_required("Admin", ...) to both views; add to api if applicable
B2 |HIGH  | Password reset link reuse/expiry | Graceful "token invalid" page | HTTP 500 NoReverseMatch: Reverse for 'login' not found | accounts/templates/password_reset_confirm.html:35 uses {% url 'login' %} (invalid); :77 uses correct accounts:login_view | Change line 35 to {% url 'accounts:login_view' %} (also handle token-invalid render)
B3 |MED   | /dashboard/ (accounts) | Requires authentication    | 200 with activity data for anonymous users | accounts/views.py:23 dashboard() - no @app_login_required | Add @app_login_required (or role gate) to dashboard view
B4 |MED   | /seances/create_session/ | Create-session form        | Empty page (no form)          | seances/templates/createSession.html is empty (dead page); real flow is planning modal | Remove route/template or implement form; update nav links
B5 |MED   | API vs web session create | Same permission rule        | API: Admin/Docteur only (403 nurse); web: any role incl. nurse | api/views.py:635 vs seances/views.py:95 | Align permission policy between API and web create_session
B6 |LOW   | Web login over plain HTTP | Login works                  | 403 CSRF failure for non-browser HTTP clients (Secure cookie not sent) | PFA/settings.py CSRF_COOKIE_SECURE/SESSION_COOKIE_SECURE=True while serving HTTP | Serve HTTPS; or disable Secure flags for dev; document
B7 |LOW   | User.save()            | Preserve any Django hash    | Re-hashes if hash not prefixed "pbkdf2_" (breaks Argon2/bcrypt) | accounts/models.py:28 | Detect hash via is_password_usable / password hashers identify
B8 |LOW   | DB machine integrity   | One active session/machine  | Pre-existing duplicate active sessions (123 x2, M200 x2) | legacy data before guard added | Data cleanup script (approved)

Observations (not bugs): /api/push/ unauthenticated (device endpoint);
threshold systems differ slightly (check_thresholds vs analyser_mesure);
surveillance page renders via JS so static HTML has no patient names.

----------------------------------------------------
12. MISSING FEATURES
----------------------------------------------------
- No rate-limiting / brute-force protection on web login or API login.
- No self-service "forgot password" email config in dev (console backend) -
  production requires SMTP env vars; reset tokens are one-time-use + 30 min TTL
  (implemented via PasswordResetRequest) - good.
- /api/push/ has no authentication/authorization or device token check.
- No mechanism to repair pre-existing double-booked machines.
- Admin site (/admin/) present but not documented; no seeded roles beyond what
  the app auto-creates.

----------------------------------------------------
13. SAFE FIX PLAN (by priority; no changes made - awaiting approval)
----------------------------------------------------
P0 - Security (do first):
  F1. Add @app_login_required + @role_required("Admin", "Docteur", ...) to
      add_doctor and ajout_infirmier (B1). Add a matching unit test.
  F2. Fix password_reset_confirm.html line 35 url tag (B2) + regression test.
P1 - Correctness:
  F3. Gate /dashboard/ with app_login_required (B3).
  F4. Align create-session permission between API and web (B5).
P2 - Hygiene:
  F5. Remove or implement /seances/create_session/ empty page (B4).
  F6. Data cleanup for double-booked machines (B8) - only with your approval.
  F7. Document HTTPS requirement; consider disabling Secure flags in dev (B6).
  F8. Make User.save() hash-detection robust (B7).
P3 - Optional hardening:
  F9. Add login rate-limiting (django-axes / throttling).
  F10. Add authentication/token to /api/push/ for device data.
  F11. Unify threshold logic (check_thresholds vs analyser_mesure).

----------------------------------------------------
TEST ARTIFACTS CREATED DURING THIS AUDIT (for cleanup - delete only on approval)
----------------------------------------------------
Users (id | username | email):
  31 | anon_nurse_x     | anon_nurse_x@example.com      (proves B1)
  32 | anon_doctor_x    | anon_doctor_x@example.com     (proves B1)
  33 | qa_nurse_test    | qa_nurse@test.local           (role/first-login tests)
  34 | qa_doctor_test   | qa_doctor@test.local          (reset-flow test)
  35 | qa_admin_test    | qa_admin@test.local           (role tests)
  36 | api_test_admin   | api_test_admin@test.local     (API role test)
  37 | api_test_doctor  | api_test_doctor@test.local    (API role test)
  38 | api_test_admin2  | api_test_admin2@test.local    (API role test)
Sessions (all closed via normal flows, no cleanup needed):
  c9f05db6 (terminée), dadf4ef9 (terminée - ended prior test session),
  24a26125 (annulée), 2e9f2c86 (annulée)
====================================================
END OF AUDIT - awaiting user approval before any fixes or cleanup.

====================================================
14. FIXES VERIFICATION (B1–B5) — FINAL STATUS
====================================================
Date: 2026-08-18 (verification run after fixes applied)
Overall B1–B5 verdict: **PASS**

All fixes from the QA audit were implemented with minimal, targeted changes
and fully verified (Django tests, Flutter regression, runtime smoke tests,
lifecycle regression). B6, B7, B8 were NOT modified.

----------------------------------------------------
14.1 EXACT FILES CHANGED (7 files, B1–B5 only)
----------------------------------------------------
| File | Constat | Change |
|---|---|---|
| accounts/views.py | B1, B3 | `@app_login_required` + `@role_required("Admin", "Docteur", redirect_to="accounts:error")` on `ajout_infirmier`; `@app_login_required` + `@role_required("Admin", redirect_to="accounts:error")` on `add_doctor`; `@app_login_required` on `dashboard` + `current_user` in context |
| accounts/templates/password_reset_confirm.html | B2 | Line 35: `{% url 'login' %}` → `{% url 'accounts:login_view' %}` |
| seances/views.py | B4 | GET `create_session`: `render('createSession.html')` → `redirect("seances:planning")` |
| seances/templates/planning.html | B5 | "Nouvelle séance" button gated `{% if current_user.role.name == "Admin" or ... "Docteur" %}`; JS null-safe (`if (newSessionBtn)`) |
| accounts/tests.py | Tests | `AccountCreationAuthorizationTests` (9), `DashboardAuthorizationTests` (2), `PasswordResetTests` (5) |
| seances/tests.py | Tests | `CreateSessionPageTests` (7); `SearchSessionsTests` preserved |
| api/tests.py | Tests | `test_session_create_api_nurse_forbidden`, `test_session_create_api_anonymous_forbidden`; doctor create test preserved |

----------------------------------------------------
14.2 B1 — CRITICAL: unauthenticated account creation
----------------------------------------------------
- Issue: ANY anonymous visitor could POST /add-doctor/ and /nurses/ajouter/
  to create Docteur/Infirmier accounts (verified with anon_doctor_x,
  anon_nurse_x).
- Root cause: accounts/views.py add_doctor (line ~346) and ajout_infirmier
  (line ~317) had NO @app_login_required / @role_required decorators.
- Fix: added @app_login_required + role gate on both views.
  - add_doctor: Admin only (redirect to accounts:error).
  - ajout_infirmier: Admin/Docteur (redirect to accounts:error).
- Before: anonymous POST succeeded -> account created.
- After: anonymous GET/POST -> 302 (redirect to login /); nurse on
  add-doctor -> 302 /error/; doctor on add-doctor -> 302 /error/;
  doctor & admin on ajout_infirmier -> 302 /nurses/ (allowed, GET->list);
  admin on add-doctor -> 302 /docteurs/ (allowed).
- Regression tests: AccountCreationAuthorizationTests (9 tests).
- Runtime verification: PASS (anon POST rejected, no users created;
  full role matrix re-run OK).
- No anon_doc2/anon_nurse2 created during verification.

----------------------------------------------------
14.3 B2 — HIGH: password reset HTTP 500 on invalid/reused token
----------------------------------------------------
- Issue: invalid/expired/reused reset links produced HTTP 500
  (NoReverseMatch on {% url 'login' %}).
- Root cause: accounts/templates/password_reset_confirm.html:35 used
  {% url 'login' %} (no such URL name); line 77 already used the correct
  accounts:login_view.
- Fix: line 35 -> {% url 'accounts:login_view' %}. Token security logic
  (TimestampSigner 30-min TTL + one-time-use via PasswordResetRequest.used_at)
  untouched.
- Before: invalid token -> 500.
- After: invalid/expired/reused token -> 200 with "Lien invalide ou expiré"
  page; valid token -> form; valid reset -> 302 to login, password changed,
  token consumed (reuse -> invalid page again).
- Regression tests: PasswordResetTests (5 tests) incl. hand-crafted expired
  token (TimestampSigner, timestamp -7200s).
- Runtime verification: PASS (valid token form + reset; invalid token 200;
  reused token 200 invalid; expired token 200 invalid; tokens NOT reusable).

----------------------------------------------------
14.4 B3 — MEDIUM: /dashboard/ anonymous access
----------------------------------------------------
- Issue: GET /dashboard/ returned 200 with the user-activity table to
  anonymous visitors.
- Root cause: accounts/views.py dashboard() had no @app_login_required.
- Fix: added @app_login_required and passed current_user in context
  (base.html requires it).
- Before: anonymous -> 200 dashboard content.
- After: anonymous -> 302 to login (/); authenticated -> 200.
- Regression tests: DashboardAuthorizationTests (2 tests).
- Runtime verification: PASS.

----------------------------------------------------
14.5 B4 — MEDIUM: dead create-session page
----------------------------------------------------
- Issue: GET /seances/create_session/ rendered an empty dead template
  (createSession.html), while the real flow is the planning modal AJAX POST.
- Root cause: seances/views.py create_session GET branch rendered the empty
  template.
- Fix: GET -> redirect("seances:planning"). POST/canonical AJAX flow
  (used by the planning modal) untouched.
- Before: GET -> 200 empty page.
- After: GET -> 302 /seances/ (planning).
- Regression tests: CreateSessionPageTests.test_get_create_session_redirects_to_planning.
- Runtime verification: PASS (doctor GET -> 302 /seances/; doctor/admin POST
  -> 200 {"success": true, "id": ...}; nurse POST -> 302 /error/).

----------------------------------------------------
14.6 B5 — MEDIUM: API vs web session-create permission mismatch
----------------------------------------------------
- Issue (audit finding): API create-session was Admin/Docteur only, but the
  web create_session view had no role gate, and the planning "Nouvelle séance"
  button was visible to all roles.
- Root cause discovered during fix: web create_session ALREADY had
  @role_required("Admin", "Docteur") (seances/views.py:92-93) - backend was
  already unified with the API. The only real gap was UI: the button was
  rendered for every role.
- Fix: planning.html button wrapped in `{% if current_user.role.name ==
  "Admin" or current_user.role.name == "Docteur" %}`; JS null-safe
  (`const newSessionBtn = ...; if (newSessionBtn) {...}`).
- Before: nurse saw (and could click) "Nouvelle séance"; backend would
  redirect nurse to /error/ on POST.
- After: nurse does NOT see the button; Admin/Docteur see it and can create
  sessions via the canonical modal.
- Regression tests: CreateSessionPageTests (button hidden for nurse / shown
  for admin; nurse POST blocked; doctor/admin POST allowed; anonymous
  blocked) + api/tests.py (nurse 403, anonymous 401, doctor preserved).
- Runtime verification: PASS (nurse no button, admin button; nurse POST
  302 /error/; doctor/admin POST 200 + session created; API nurse 403 /
  anonymous 401 / doctor 201).

----------------------------------------------------
14.7 DJANGO RESULTS
----------------------------------------------------
- python manage.py check: System check identified no issues (0 silenced).
- python manage.py test api seances monitoring accounts:
  Ran 58 tests in ~55-83s -> OK (0 failures).
  (Added 25 regression tests on top of the original 34; the audit's original
  run covered api+seances+monitoring=34.)

----------------------------------------------------
14.8 FLUTTER RESULTS
----------------------------------------------------
- flutter analyze : No issues found.
- flutter test    : All 21 tests passed.
- flutter build web: SUCCESS ("Built build\web"). Wasm dry-run warnings from
  flutter_secure_storage_web are pre-existing and do not affect the JS build.

----------------------------------------------------
14.9 RUNTIME SMOKE RESULTS (B1–B5)
----------------------------------------------------
- Anonymous dashboard          : 302 -> / (no dashboard content)          PASS
- Anonymous doctor creation    : rejected, no user created                PASS
- Anonymous nurse creation     : rejected, no user created                PASS
- Password reset invalid token : 200, "Lien invalide ou expiré", not 500   PASS
- Password reset reused token  : 200, invalid page, not 500, not reusable  PASS
- Password reset expired token : 200, invalid page, not 500                PASS
- Session permissions          : anon forbidden; nurse forbidden (302 /error/);
                                doctor allowed; admin allowed             PASS
- Canonical create-session flow: GET redirects to /seances/; POST modal flow
                                works for Admin/Docteur                   PASS
- B5 UI                        : nurse no button; admin/docteur button     PASS
- Test users (8) still present, no cleanup performed                      PASS

----------------------------------------------------
14.10 SESSION LIFECYCLE REGRESSION (existing behavior preserved)
----------------------------------------------------
New lifecycle session 0f4179d5-a940-4258-8021-40541a768c0e (M001):
  CREATE (web modal)      -> "planifiée"                                   PASS
  START (API /start/)     -> "en cours", pre-measurements recorded,
                             machine M001 -> Reserve                        PASS
  LiveMeasurement (/api/push/)
                          -> 2 real readings pushed (Qb 312->318, PA 128->131,
                             UF 640->670)                                   PASS
  /api/monitoring/live/   -> session listed with real values (Qb 318, PA 131,
                             UF 670) - NOT null placeholders                PASS
  Web Surveillance        -> 200, loads /api/real-monitoring/ which returns
                             the pushed values (Qb 318/312 on M001)         PASS
  Flutter Surveillance    -> uses /api/monitoring/live/ (same payload shape
                             verified by model + unit tests)               PASS
Real measurement values received and rendered (no null placeholders).      PASS

----------------------------------------------------
14.11 MACHINE SINGLE-ACTIVE-SESSION GUARD (unchanged behavior)
----------------------------------------------------
- Attempted API start of a second session (7a474a6e) on occupied M001:
  HTTP 409 "Machine déjà occupée par une séance en cours"; session stayed
  "planifiée".                                                             PASS
- Attempted web pre POST on the same occupied machine: 302 -> planning,
  session stayed "planifiée".                                              PASS
- B8 double-booked records NOT modified:
  machine 123 -> status Reserve, still 2 "en cours" sessions;
  machine M200 -> status Reserve, still 2 "en cours" sessions.             PASS

----------------------------------------------------
14.12 EXPLICIT CONFIRMATIONS
----------------------------------------------------
- B6 NOT modified (settings.py cookies untouched).
- B7 NOT modified (accounts/models.py User.save untouched).
- B8 NOT modified (double-booked machines 123/M200 left in place).
- No test-user cleanup performed (anon_nurse_x, anon_doctor_x, qa_nurse_test,
  qa_doctor_test, qa_admin_test, api_test_admin, api_test_doctor,
  api_test_admin2 all present).
- No test-session cleanup performed (50b76cef and all lifecycle/guard sessions
  kept).
- MQTT/demo simulator behavior NOT modified.
- No commit performed.
- No push performed.

----------------------------------------------------
14.13 REMAINING ISSUES
----------------------------------------------------
- No remaining B1–B5 functional issues.
- Pre-existing / out-of-scope items still open (unchanged by this work):
  B6 (Secure cookie / HTTP login 403 for non-browser clients), B7
  (User.save pbkdf2-only hash detection), B8 (pre-existing double-booked
  machines 123/M200 - data anomaly), /api/push/ unauthenticated (device
  endpoint), no login rate-limiting, minor UI/backend raspi link mismatch.
- Environment note: Django dev server listened on IPv4 only; a "Cannot
  connect to API" report was traced to an IPv6/IPv4 localhost mismatch
  (browser resolves localhost -> ::1 first; Django on 127.0.0.1 only).
  Resolved at runtime by also listening on [::1]:8000 - no application code
  change. See B1_B5_FIX_REPORT.md section 5 for details.
