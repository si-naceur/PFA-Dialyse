import json
from datetime import date
from django.test import TestCase, Client
from accounts.models import User, Role
from patients.models import Patient
from machines.models import Machine, RaspiDevice
from seances.models import Seance, Alert as SeanceAlert
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
        self.assertEqual(res.json()["data"]["id"], self.patient.id)

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
