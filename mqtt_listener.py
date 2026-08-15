"""
mqtt_listener.py
----------------
Écoute les messages MQTT (topic dialysis/machine/#)
et les enregistre dans Django exactement comme l'endpoint HTTP /api/push/.

Usage:
  python mqtt_listener.py

Pré-requis:
  - Mosquitto qui tourne
  - Django DB accessible (même settings)
  - Une séance "En cours" pour la machine (sinon le message est ignoré)
"""

import json
import os
import sys
import django
import time

# ===================== Django setup =====================
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "PFA.settings")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
django.setup()

from machines.models import Machine
from seances.models import Seance
from monitoring.models import LiveMeasurement, Alerte
from monitoring.services import check_thresholds

# ===================== MQTT config =====================
MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "dialysis/machine/#"

# =======================================================

def save_measurement(data: dict) -> bool:
    """
    Même logique que api.views.push_measurement
    """
    try:
        machine_id = data.get("machine_id")
        if not machine_id:
            print("[ERROR] machine_id manquant")
            return False

        try:
            machine = Machine.objects.get(machine_id=machine_id)
        except Machine.DoesNotExist:
            print(f"[ERROR] Machine '{machine_id}' introuvable en base")
            return False

        seance = Seance.objects.filter(
            machine=machine,
            status="en cours"
        ).first()

        if not seance:
            print(f"[WARN] Aucune séance 'En cours' pour {machine_id} -> message ignoré")
            return False

        measurement = LiveMeasurement.objects.create(
            seance=seance,
            Debit_sang=data.get("Qb"),
            Taux_UF=data.get("UF_rate"),
            PA=data.get("PA"),
            PTM=data.get("PTM"),
            PV=data.get("PV"),
            Volume_UF=data.get("UF_volume"),
            Heparine=data.get("Heparin"),
        )

        # Même logique d'alertes que api.views.push_measurement :
        # 1) Alertes "monitoring" (Alerte, liées à la mesure)
        # 2) Alertes "séance" (seances.Alert, compatibles Dashboard/Alerts)
        from django.utils import timezone
        from datetime import timedelta
        from monitoring.alerte import analyser_mesure

        dedup_cutoff = timezone.now() - timedelta(minutes=5)
        monitoring_alerts = check_thresholds(measurement)
        for niveau, message in monitoring_alerts:
            already = Alerte.objects.filter(
                reading__seance=seance,
                niveau=niveau,
                message=message,
                timestamp__gte=dedup_cutoff,
            ).exists()
            if not already:
                Alerte.objects.create(reading=measurement, niveau=niveau, message=message)

        try:
            rich_alerts = analyser_mesure(measurement)
            from seances.models import Alert as SeanceAlert
            for al in rich_alerts:
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

        print(f"[SAVED] LiveMeasurement {measurement.id} | Qb={data.get('Qb')} PA={data.get('PA')}")
        return True

    except Exception as e:
        print(f"[ERROR] save_measurement: {e}")
        return False


def on_connect(client, userdata, flags, reason_code, properties=None):
    if reason_code == 0 or str(reason_code) == "Success":
        print(f"[MQTT] Connected to {MQTT_BROKER}:{MQTT_PORT}")
        client.subscribe(MQTT_TOPIC)
        print(f"[MQTT] Subscribed -> {MQTT_TOPIC}")
    else:
        print(f"[MQTT] Connection failed: {reason_code}")


def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode("utf-8")
        data = json.loads(payload)
        print(f"\n[MQTT] Received on {msg.topic}")
        print(f"       {payload[:120]}...")
        save_measurement(data)
    except json.JSONDecodeError:
        print("[ERROR] Invalid JSON")
    except Exception as e:
        print(f"[ERROR] on_message: {e}")


def main():
    try:
        import paho.mqtt.client as mqtt
    except ImportError:
        print("Install paho-mqtt:  pip install paho-mqtt")
        sys.exit(1)

    # Compatible avec les nouvelles versions de paho-mqtt
    try:
        client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="django-mqtt-listener")
    except AttributeError:
        client = mqtt.Client(client_id="django-mqtt-listener")

    client.on_connect = on_connect
    client.on_message = on_message

    print("=" * 50)
    print("  MQTT Listener for Django")
    print(f"  Broker : {MQTT_BROKER}:{MQTT_PORT}")
    print(f"  Topic  : {MQTT_TOPIC}")
    print("=" * 50)

    while True:
        try:
            client.connect(MQTT_BROKER, MQTT_PORT, 60)
            client.loop_forever()
        except Exception as e:
            print(f"[MQTT] Connection lost: {e} -> retry in 5s")
            time.sleep(5)


if __name__ == "__main__":
    main()