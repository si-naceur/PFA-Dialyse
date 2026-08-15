import json
import base64
from datetime import date
from unittest import mock
from django.test import TestCase, Client
from accounts.models import User, Role, PasswordResetRequest
from patients.models import Patient
from machines.models import Machine, RaspiDevice
from seances.models import Seance, Alert as SeanceAlert
from seances.models import PreSessionMeasurements, PostSessionMeasurements, RapportSeance
from monitoring.models import LiveMeasurement, Alerte

class Phase1ApiTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.doctor_role = Role.objects.create(name="Docteur")
        self.nurse_role = Role.objects.create(name="Infirmier")
        self.doctor_user = User.objects.create(
            username="doc_test",
            password="password123",
            role=self.doctor_role,
            email="doc@test.com",
        )
        self.nurse_user = User.objects.create(
            username="nurse_test",
            password="password123",
            role=self.nurse_role,
            email="nurse@test.com",
        )
        self.patient = Patient.objects.create(
            first_name="Ahmed",
            last_name="Ben Salah",
            date_of_birth=date(1980, 5, 20),
            age=45,
            groupe_sanguin="O+",
            type_de_dialyse="Hémodialyse",
        )
        self.machine = Machine.objects.create(
            machine_id="M100",
            model="Model-X",
            manufacturer="DialysisCorp",
            status="Prete",
        )
        self.raspi = RaspiDevice.objects.create(
            raspi_id="RASPI-TEST",
            machine=self.machine,
            is_active=True,
        )
        self.seance = Seance.objects.create(
            patient=self.patient,
            machine=self.machine,
            session_date=date.today(),
            start_hour="08:00",
            duration=4,
            status="planifiée",
            debit=60,
        )

    def _login(self, user):
        session = self.client.session
        session["app_user_id"] = user.id
        session.save()

    def test_mobile_login_success(self):
        res = self.client.post(
            "/api/login/",
            data=json.dumps({"username": "doc_test", "password": "password123"}),
            content_type="application/json",
        )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(data["user"]["username"], "doc_test")
        self.assertTrue(data.get("sessionid"))

    def test_monitoring_live_via_session_header(self):
        """Flutter Web sends X-Session-Id when Cookie cannot be set."""
        login = self.client.post(
            "/api/login/",
            data=json.dumps({"username": "doc_test", "password": "password123"}),
            content_type="application/json",
        )
        session_id = login.json()["sessionid"]
        # Fresh client with no cookies — only the header, like Flutter Web.
        bare = Client()
        res = bare.get(
            "/api/monitoring/live/",
            HTTP_X_SESSION_ID=session_id,
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json()["success"])
        res2 = bare.get(
            "/api/monitoring/?sort=-login_at",
            HTTP_X_SESSION_ID=session_id,
        )
        self.assertEqual(res2.status_code, 200)

    def test_mobile_login_fail(self):
        res = self.client.post(
            "/api/login/",
            data=json.dumps({"username": "doc_test", "password": "wrongpassword"}),
            content_type="application/json",
        )
        self.assertEqual(res.status_code, 401)
        data = res.json()
        self.assertFalse(data.get("success"))

    def test_mobile_logout(self):
        self._login(self.doctor_user)
        res = self.client.post("/api/logout/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json().get("success"))
        self.assertNotIn("app_user_id", self.client.session)

    def test_password_reset_request_known_email(self):
        """Same neutral message, token persisted, email sent once."""
        with mock.patch("api.views.send_mail") as mock_mail:
            res = self.client.post(
                "/api/password-reset/request/",
                data=json.dumps({"email": "doc@test.com"}),
                content_type="application/json",
            )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(
            data["message"],
            "Si un compte existe avec cet email, un lien a été envoyé.",
        )
        self.assertEqual(mock_mail.call_count, 1)
        request = PasswordResetRequest.objects.filter(user=self.doctor_user).first()
        self.assertIsNotNone(request)
        self.assertTrue(request.token)
        self.assertFalse(request.is_used())

    def test_password_reset_request_unknown_email(self):
        """Neutral message, no token row created, no email sent."""
        with mock.patch("api.views.send_mail") as mock_mail:
            res = self.client.post(
                "/api/password-reset/request/",
                data=json.dumps({"email": "does-not-exist@test.com"}),
                content_type="application/json",
            )
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(
            data["message"],
            "Si un compte existe avec cet email, un lien a été envoyé.",
        )
        self.assertEqual(mock_mail.call_count, 0)
        self.assertEqual(PasswordResetRequest.objects.count(), 0)

    def test_password_reset_request_requires_json_email(self):
        res = self.client.post(
            "/api/password-reset/request/",
            data=json.dumps({"email": ""}),
            content_type="application/json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertFalse(res.json().get("success"))
        res2 = self.client.get("/api/password-reset/request/")
        self.assertEqual(res2.status_code, 405)

    def test_profile_photo_upload_cropped_image(self):
        """Same cropped_image base64 contract as accounts.views.profile."""
        User.objects.filter(id=self.doctor_user.id).update(first_login=False)
        self.doctor_user.refresh_from_db()
        self._login(self.doctor_user)
        from accounts.models import Profile
        # 1x1 PNG as a data-URL, like the web CropperJS output.
        png_b64 = (
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlE"
            "QVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
        )
        data_url = f"data:image/png;base64,{png_b64}"
        res = self.client.put(
            "/api/profile/",
            data=json.dumps({"cropped_image": data_url}),
            content_type="application/json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json().get("success"))
        profile = Profile.objects.get(user=self.doctor_user)
        self.assertTrue(profile.image)
        self.assertTrue(res.json()["data"]["photo_url"])

    def test_profile_photo_upload_invalid_image(self):
        User.objects.filter(id=self.doctor_user.id).update(first_login=False)
        self.doctor_user.refresh_from_db()
        self._login(self.doctor_user)
        res = self.client.put(
            "/api/profile/",
            data=json.dumps({"cropped_image": "not-a-data-url"}),
            content_type="application/json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertFalse(res.json().get("success"))

    def test_profile_payload_has_photo_url(self):
        self._login(self.doctor_user)
        res = self.client.get("/api/profile/")
        self.assertEqual(res.status_code, 200)
        self.assertIn("photo_url", res.json()["data"])

    def test_patients_api_unauthorized(self):
        res = self.client.get("/api/patients/")
        self.assertEqual(res.status_code, 401)

    def test_patients_api(self):
        self._login(self.doctor_user)
        res = self.client.get("/api/patients/")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertEqual(len(data["data"]), 1)
        self.assertEqual(data["data"][0]["first_name"], "Ahmed")

    def test_patients_api_search(self):
        self._login(self.doctor_user)
        res = self.client.get("/api/patients/?search=Salah")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.json()["data"]), 1)

    def test_patient_detail_api(self):
        self._login(self.doctor_user)
        res = self.client.get(f"/api/patients/{self.patient.id}/")
        self.assertEqual(res.status_code, 200)
        # Patient ids are always strings on the API contract (see _patient_pk).
        self.assertEqual(res.json()["data"]["id"], str(self.patient.id))

    def test_machines_api(self):
        self._login(self.doctor_user)
        res = self.client.get("/api/machines/")
        self.assertEqual(res.status_code, 200)
        data = res.json()["data"]
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["raspi"]["raspi_id"], "RASPI-TEST")

    def test_machine_detail_api(self):
        self._login(self.doctor_user)
        res = self.client.get(f"/api/machines/{self.machine.id}/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["data"]["machine_id"], "M100")

    def test_sessions_list_api(self):
        self._login(self.doctor_user)
        res = self.client.get("/api/sessions/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.json()["data"]), 1)

    def test_session_create_api_doctor(self):
        self._login(self.doctor_user)
        payload = {
            "patient_id": self.patient.id,
            "machine_id": self.machine.id,
            "session_date": "2026-09-01",
            "start_time": "10:00",
            "duration": 4,
            "debit": 30,
        }
        res = self.client.post("/api/sessions/", data=json.dumps(payload), content_type="application/json")
        self.assertEqual(res.status_code, 201)
        self.assertTrue(res.json().get("success"))

    def test_session_start_end_cancel(self):
        self._login(self.doctor_user)
        # Start session
        res_start = self.client.post(
            f"/api/sessions/{self.seance.id}/start/",
            data=json.dumps({"weight": 70.0, "blood_pressure": "120/80", "heart_rate": 72, "temperature": 36.6, "saturation": 98.0}),
            content_type="application/json",
        )
        self.assertEqual(res_start.status_code, 200)
        self.seance.refresh_from_db()
        self.assertEqual(self.seance.status, "en cours")

        # End session
        res_end = self.client.post(
            f"/api/sessions/{self.seance.id}/end/",
            data=json.dumps({"weight": 68.0, "complications": "Aucune"}),
            content_type="application/json",
        )
        self.assertEqual(res_end.status_code, 200)
        self.seance.refresh_from_db()
        self.assertEqual(self.seance.status, "terminée")

        # Ending a session must generate exactly one rapport (OneToOne).
        rapport = RapportSeance.objects.filter(seance=self.seance).first()
        self.assertIsNotNone(rapport)
        self.assertIn(rapport.qualite_seance, ("normale", "difficile"))
        self.assertTrue(rapport.contenu_html.strip())
        self.assertTrue(rapport.nom_fichier.endswith(".html"))
        self.assertEqual(RapportSeance.objects.filter(seance=self.seance).count(), 1)

    def test_rapport_generation_content(self):
        """The rapport must embed real session data (charts, alerts, pre/post)."""
        self._login(self.doctor_user)
        PreSessionMeasurements.objects.create(
            seance=self.seance, weight=80.5, blood_pressure="120/80",
            heart_rate=72, temperature=36.6, saturation=98.0,
        )
        PostSessionMeasurements.objects.create(
            seance=self.seance, weight=78.9, blood_pressure="110/75",
            heart_rate=70, temperature=36.4, saturation=99.0,
        )
        self.seance.status = "en cours"
        self.seance.save()
        LiveMeasurement.objects.create(
            seance=self.seance, Debit_sang=200, PA=110,
            PTM=60, PV=120, Taux_UF=500, Volume_UF=1000, Heparine=800,
        )
        SeanceAlert.objects.create(
            seance=self.seance, alert_type="PA", message="PA élevée",
            danger_level="HIGH", recommended_action="Vérifier",
        )
        from seances.rapport import generate_rapport
        rapport = generate_rapport(self.seance)
        self.assertIn(self.patient.first_name, rapport.contenu_html)
        self.assertIn(self.patient.last_name, rapport.contenu_html)
        self.assertIn("chartPression", rapport.contenu_html)
        # The alert message is embedded inside the json_script block (JSON
        # escaped), and the quality badge renders "difficile" when a HIGH alert
        # or complication exists.
        self.assertIn("PA ", rapport.contenu_html)
        self.assertIn("1.60 kg", rapport.contenu_html)
        self.assertEqual(rapport.qualite_seance, "difficile")
        # Idempotency: calling again updates instead of duplicating.
        generate_rapport(self.seance)
        self.assertEqual(RapportSeance.objects.filter(seance=self.seance).count(), 1)

    def test_session_detail_api(self):
        self._login(self.doctor_user)
        self.machine.location = "Salle 1"
        self.machine.save()
        self.seance.status = "en cours"
        self.seance.save()
        meas = LiveMeasurement.objects.create(
            seance=self.seance,
            Debit_sang=200,
            PA=110,
            PTM=60,
            PV=120,
            Taux_UF=500,
            Volume_UF=1000,
        )
        res = self.client.get(f"/api/sessions/{self.seance.id}/")
        self.assertEqual(res.status_code, 200)
        data = res.json()["data"]
        self.assertEqual(data["machine"]["location"], "Salle 1")
        self.assertEqual(data["machine"]["status"], "Prete")
        self.assertEqual(data["readings_count"], 1)
        self.assertEqual(data["last_reading"]["volume_uf"], 1000)
        self.assertEqual(data["last_reading"]["debit_sang"], 200)
        self.assertEqual(data["readings"][0]["pa"], 110)
        self.assertEqual(data["readings"][0]["qb"], 200)
        self.assertGreaterEqual(data["readings"][0]["time"], 0)

    def test_dashboard_api(self):
        self._login(self.doctor_user)
        res = self.client.get("/api/dashboard/")
        self.assertEqual(res.status_code, 200)
        kpis = res.json()["kpis"]
        self.assertIn("active_sessions", kpis)
        self.assertIn("available_machines", kpis)
        self.assertIn("total_machines", kpis)

    def test_monitoring_live_requires_session(self):
        res = self.client.get("/api/monitoring/live/")
        self.assertEqual(res.status_code, 401)
        self._login(self.doctor_user)
        res = self.client.get("/api/monitoring/live/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json()["success"])

    def test_seance_debit_api(self):
        self.seance.status = "en cours"
        self.seance.debit = 30
        self.seance.save()
        res = self.client.get("/api/seance/debit/?machine_id=M100")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["debit"], 30)

    def test_push_measurement_pipeline(self):
        self.seance.status = "en cours"
        self.seance.save()
        payload = {
            "machine_id": "M100",
            "Qb": 80,          # Critical low -> trigger alert
            "UF_rate": 500,
            "PA": 190,         # High -> trigger alert
            "PTM": 50,
            "PV": 100,
            "UF_volume": 1000,
            "Heparin": 5,
        }
        res = self.client.post("/api/push/", data=json.dumps(payload), content_type="application/json")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertTrue(data.get("success"))
        self.assertGreater(data.get("monitoring_alerts_created", 0), 0)
        self.assertGreater(data.get("seance_alerts_created", 0), 0)

    def test_alerts_api_and_ack_resolve(self):
        self._login(self.doctor_user)
        self.seance.status = "en cours"
        self.seance.save()
        meas = LiveMeasurement.objects.create(seance=self.seance, PA=210)
        m_alert = Alerte.objects.create(reading=meas, niveau="RED", message="PA trop élevée", status="NEW")
        s_alert = SeanceAlert.objects.create(
            seance=self.seance,
            alert_type="PA",
            message="PA très élevée",
            danger_level="HIGH",
            recommended_action="Réduire débit",
        )
        res = self.client.get("/api/alerts/")
        self.assertEqual(res.status_code, 200)
        self.assertGreaterEqual(len(res.json()["data"]), 2)

        # Ack monitoring alert
        res_ack = self.client.post(f"/api/alerts/{m_alert.id}/ack/")
        self.assertEqual(res_ack.status_code, 200)
        m_alert.refresh_from_db()
        self.assertEqual(m_alert.status, "ACK")

        # Resolve monitoring alert
        res_res = self.client.post(f"/api/alerts/{m_alert.id}/resolve/")
        self.assertEqual(res_res.status_code, 200)
        m_alert.refresh_from_db()
        self.assertEqual(m_alert.status, "RESOLVED")
