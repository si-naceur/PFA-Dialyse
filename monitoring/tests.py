from io import StringIO

from django.core.management import call_command
from django.test import TestCase, override_settings

from machines.models import Machine
from monitoring.models import LiveMeasurement
from patients.models import Patient
from seances.models import Seance


class RunDemoSimulationTests(TestCase):
    def setUp(self):
        self.patient = Patient.objects.create(
            first_name="Alice",
            last_name="Durand",
            date_of_birth="1990-01-01",
            age=35,
            groupe_sanguin="A+",
            type_de_dialyse="Hémodialyse",
        )

    def _machine(self, machine_id):
        return Machine.objects.create(machine_id=machine_id)

    def _session(self, patient, machine, status="en cours"):
        return Seance.objects.create(
            patient=patient,
            machine=machine,
            status=status,
        )

    @override_settings(DEMO_MODE=False)
    def test_demo_mode_disabled_creates_no_measurements(self):
        machine = self._machine("M-100")
        self._session(self.patient, machine, status="en cours")

        out, err = StringIO(), StringIO()
        call_command("run_demo_simulation", "--cycles", "1", stdout=out, stderr=err)

        self.assertEqual(LiveMeasurement.objects.count(), 0)
        self.assertIn("DEMO_MODE is disabled.", err.getvalue())

    @override_settings(DEMO_MODE=True)
    def test_single_active_session_gets_one_measurement(self):
        machine = self._machine("M-100")
        seance = self._session(self.patient, machine, status="en cours")

        call_command("run_demo_simulation", "--cycles", "1", stdout=StringIO())

        measurements = LiveMeasurement.objects.filter(seance=seance)
        self.assertEqual(measurements.count(), 1)
        lm = measurements.first()
        self.assertIsNotNone(lm.Debit_sang)
        self.assertIsNotNone(lm.PA)
        self.assertIsNotNone(lm.PTM)
        self.assertIsNotNone(lm.PV)
        self.assertIsNotNone(lm.Volume_UF)
        self.assertIsNotNone(lm.Taux_UF)
        self.assertIsNotNone(lm.Heparine)

    @override_settings(DEMO_MODE=True)
    def test_multiple_active_sessions_each_get_their_own_measurement(self):
        m1 = self._machine("M-100")
        m2 = self._machine("M-101")
        m3 = self._machine("M-102")
        s1 = self._session(self.patient, m1, status="en cours")
        s2 = self._session(self.patient, m2, status="en cours")
        s3 = self._session(self.patient, m3, status="en cours")

        call_command("run_demo_simulation", "--cycles", "1", stdout=StringIO())

        self.assertEqual(LiveMeasurement.objects.count(), 3)
        self.assertEqual(LiveMeasurement.objects.filter(seance=s1).count(), 1)
        self.assertEqual(LiveMeasurement.objects.filter(seance=s2).count(), 1)
        self.assertEqual(LiveMeasurement.objects.filter(seance=s3).count(), 1)

    @override_settings(DEMO_MODE=True)
    def test_no_active_sessions_creates_no_measurements(self):
        machine = self._machine("M-100")
        self._session(self.patient, machine, status="planifiée")

        call_command("run_demo_simulation", "--cycles", "1", stdout=StringIO())

        self.assertEqual(LiveMeasurement.objects.count(), 0)