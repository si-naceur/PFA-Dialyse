def check_thresholds(reading):
    alerts = []

    if reading.PA is not None:
        if reading.PA > 180:
            alerts.append(
                ("RED", "Pression artérielle trop élevée")
            )
        elif reading.PA < 80:
            alerts.append(
                ("RED", "Pression artérielle trop basse")
            )

    if reading.PV is not None and reading.PV > 250:
        alerts.append(
            ("YELLOW", "Pression veineuse élevée")
        )

    if reading.PTM is not None and reading.PTM > 100:
        alerts.append(
            ("YELLOW", "PTM élevée")
        )

    if reading.Debit_sang is not None and reading.Debit_sang < 200:
        alerts.append(
            ("RED", "Débit sanguin faible")
        )

    return alerts