"""
start_system.py
---------------
Script de démarrage rapide pour le système complet PFA-Dialyse.
Il démarre en parallèle (ou donne les commandes pour démarrer) :
1. Le service IA Qwen (qwen_api.py sur le port 8001)
2. Le serveur Django (manage.py runserver sur le port 8000)
3. Le récepteur MQTT (mqtt_listener.py)
4. Le client Edge / simulateur (edge_client.py)
"""

import sys
import subprocess
import time

PYTHON_EXEC = sys.executable

def print_banner():
    print("=" * 65)
    print("      SYSTÈME PFA-DIALYSE — PROCÉDURE DE DÉMARRAGE RAPIDE")
    print("=" * 65)
    print("\nPour exécuter le système de bout en bout, ouvrez 4 terminaux :\n")
    print("TERMINAL 1 — Service IA (qwen_api.py) :")
    print(f"  {PYTHON_EXEC} -m uvicorn qwen_api:app --port 8001 --reload\n")
    print("TERMINAL 2 — Backend Django & Dashboard :")
    print(f"  {PYTHON_EXEC} manage.py runserver 8000\n")
    print("TERMINAL 3 — Receiver MQTT Image → AI → Django :")
    print(f"  {PYTHON_EXEC} mqtt_listener.py\n")
    print("TERMINAL 4 — Client Raspberry Pi / Simulateur Edge :")
    print(f"  {PYTHON_EXEC} edge_client.py\n")
    print("=" * 65)

if __name__ == "__main__":
    print_banner()
