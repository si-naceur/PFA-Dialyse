import os
import requests
import random
import time


EDGE_API_KEY = os.environ.get('EDGE_API_KEY', 'dev-edge-key-change-me')
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
        json=data,
        headers={'X-Edge-Api-Key': EDGE_API_KEY},
    )


    print(
        "Sent:",
        data,
        "=>",
        r.json()
    )


    time.sleep(3)