"""
run_demo_simulation
-------------------
DEMO/TEST mode simulator: generates a LiveMeasurement for every currently
active session (`status="en cours"`) approximately every 3 seconds and runs
the existing alert logic (monitoring.services.check_thresholds +
monitoring.alerte.analyser_mesure) exactly like mqtt_listener.py does.

The command is gated by the `DEMO_MODE` setting and does NOT depend on MQTT,
Mosquitto or any external publisher. New sessions are discovered automatically
on each tick, so there is no hook in the START flow.

Usage:
  python manage.py run_demo_simulation            # infinite loop (Ctrl+C)
  python manage.py run_demo_simulation --cycles 3 # run 3 ticks then exit
  python manage.py run_demo_simulation --interval 1.5
"""

import random
import time
from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand
from django.utils import timezone

from monitoring.alerte import analyser_mesure
from monitoring.models import Alerte, LiveMeasurement
from monitoring.services import check_thresholds
from seances.models import Alert as SeanceAlert
from seances.models import Seance


def _generate_measurement(seance, volume_state):
    """Create one simulated LiveMeasurement for the given Seance.

    Values change on each tick and stay inside realistic normal ranges so the
    dashboard looks like a real session (Volume_UF accumulates over time).
    """
    volume = volume_state.get(seance.id, 0.0)
    volume += random.uniform(5, 15)
    volume_state[seance.id] = volume

    return LiveMeasurement.objects.create(
        seance=seance,
        Debit_sang=round(random.uniform(250, 300), 1),
        Taux_UF=round(random.uniform(400, 600), 1),
        PA=round(random.uniform(110, 160), 1),
        PTM=round(random.uniform(50, 100), 1),
        PV=round(random.uniform(150, 250), 1),
        Volume_UF=round(volume, 1),
        Heparine=round(random.uniform(4.8, 5.2), 2),
    )


def _run_alert_logic(seance, measurement):
    """Same alert pipeline as mqtt_listener.save_measurement: monitoring.Alerte
    (check_thresholds) + seances.Alert (analyser_mesure), with the same 5-minute
    dedup window. Thresholds/severity are NOT modified."""
    dedup_cutoff = timezone.now() - timedelta(minutes=5)

    for niveau, message in check_thresholds(measurement):
        already = Alerte.objects.filter(
            reading__seance=seance,
            niveau=niveau,
            message=message,
            timestamp__gte=dedup_cutoff,
        ).exists()
        if not already:
            Alerte.objects.create(reading=measurement, niveau=niveau, message=message)

    try:
        for al in analyser_mesure(measurement):
            already = SeanceAlert.objects.filter(
                seance=seance,
                alert_type=al["alert_type"],
                danger_level=al["danger_level"],
                timestamp__gte=dedup_cutoff,
            ).exists()
            if not already:
                SeanceAlert.objects.create(
                    seance=seance,
                    alert_type=al["alert_type"],
                    message=al["message"],
                    danger_level=al["danger_level"],
                    recommended_action=al["recommended_action"],
                )
    except Exception as e:
        print(f"[WARN] SeanceAlert generation skipped: {e}")


def simulate_once(volume_state):
    """Generate one measurement per active session. Returns the created rows."""
    active = Seance.objects.filter(status="en cours").select_related("machine", "patient")
    active_ids = {s.id for s in active}

    # Drop accumulated UF state for sessions that are no longer active.
    for sid in list(volume_state.keys()):
        if sid not in active_ids:
            del volume_state[sid]

    created = []
    for seance in active:
        measurement = _generate_measurement(seance, volume_state)
        _run_alert_logic(seance, measurement)
        created.append(measurement)
    return created


class Command(BaseCommand):
    help = "Generate simulated LiveMeasurements for active sessions (DEMO/TEST mode)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--interval",
            type=float,
            default=3.0,
            help="Seconds between ticks (default: 3.0).",
        )
        parser.add_argument(
            "--cycles",
            type=int,
            default=0,
            help="Number of ticks before exiting (default: 0 = run forever).",
        )

    def handle(self, *args, **options):
        if not settings.DEMO_MODE:
            self.stderr.write("DEMO_MODE is disabled.")
            self.stderr.write("Set DEMO_MODE=true to run the demo simulator.")
            return

        interval = options["interval"]
        cycles = options["cycles"]
        volume_state = {}

        self.stdout.write("DEMO simulation started (DEMO_MODE=true).")
        self.stdout.write(
            f"Generating a measurement every {interval}s for each active session."
        )

        n = 0
        try:
            while cycles == 0 or n < cycles:
                created = simulate_once(volume_state)
                n += 1
                if created:
                    self.stdout.write(
                        f"[DEMO] tick {n}: created {len(created)} measurement(s)"
                    )
                elif cycles == 0:
                    self.stdout.write(
                        f"[DEMO] tick {n}: no active session — waiting"
                    )
                if cycles == 0 or n < cycles:
                    time.sleep(interval)
        except KeyboardInterrupt:
            self.stdout.write("DEMO simulation stopped.")