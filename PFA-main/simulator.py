import requests
import time
import random


API_URL = "http://127.0.0.1:8000/api/push/"

MACHINE_ID = "M001"


def generate_measurement():

    return {
        "machine_id": MACHINE_ID,

        # Débit sanguin Qb
        "Qb": random.randint(200, 300),

        # Taux UF
        "UF_rate": round(random.uniform(0.8, 1.5), 2),

        # Pression artérielle machine
        "PA": random.randint(100, 150),

        # Pression transmembranaire
        "PTM": random.randint(30, 100),

        # Pression veineuse
        "PV": random.randint(100, 220),

        # Volume UF
        "UF_volume": random.randint(300, 1000),

        # Héparine
        "Heparin": random.randint(2, 8),
    }


def send_data():

    while True:

        data = generate_measurement()

        try:
            response = requests.post(
                API_URL,
                json=data
            )

            print(
                "Sent:",
                data,
                "=>",
                response.json()
            )

        except Exception as e:
            print("Error:", e)


        time.sleep(5)



if __name__ == "__main__":
    send_data()