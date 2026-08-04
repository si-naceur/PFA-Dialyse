import paho.mqtt.client as mqtt
import json
import time


BROKER = "localhost"
PORT = 1883

TOPIC = "dialysis/machine/M001"


client = mqtt.Client()

client.connect(
    BROKER,
    PORT,
    60
)


while True:

    data = {
        "machine_id": "M001",
        "Qb": 280,
        "UF_rate": 500,
        "PA": 220,
        "PTM": 70,
        "PV": 200,
        "UF_volume": 500,
        "Heparin": 5
    }


    message = json.dumps(data)


    client.publish(
        TOPIC,
        message
    )


    print("MQTT SENT:")
    print(message)


    time.sleep(3)