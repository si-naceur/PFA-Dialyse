import requests
import random
import time


URL = "http://127.0.0.1:8000/api/push/"


while True:

    data = {
    "machine_id": "M001",
    "Qb": 280,
    "PA": 220,
    "PTM": 70,
    "PV": 200,
    "UF_volume": 500
}


    r = requests.post(
        URL,
        json=data
    )


    print(
        "Sent:",
        data,
        "=>",
        r.json()
    )


    time.sleep(3)