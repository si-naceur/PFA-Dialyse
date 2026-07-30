from .models import Alerte


def check_thresholds(reading):

    alerts = []

    if reading.PA > 180:
        alerts.append(
            ("RED", "Pression artérielle trop élevée")
        )

    elif reading.PA < 80:
        alerts.append(
            ("RED", "Pression artérielle trop basse")
        )


    if reading.PV > 250:
        alerts.append(
            ("YELLOW", "Pression veineuse élevée")
        )


    if reading.PTM > 100:
        alerts.append(
            ("YELLOW", "PTM élevée")
        )


    if reading.Debit_sang < 200:
        alerts.append(
            ("RED", "Débit sanguin faible")
        )


    # Enregistrer les alertes dans la base
    for niveau, message in alerts:
        Alerte.objects.create(
            reading=reading,
            niveau=niveau,
            message=message
        )


    return alerts