def check_thresholds(reading):

    alerts = []

    # Pression artérielle
    if reading.PA is not None:
        if reading.PA > 180:
            alerts.append(
                ("HIGH", "Pression artérielle trop élevée")
            )

        elif reading.PA < 80:
            alerts.append(
                ("HIGH", "Pression artérielle trop basse")
            )


    # Pression veineuse
    if reading.PV is not None:
        if reading.PV > 280:
            alerts.append(
                ("MEDIUM", "Pression veineuse élevée")
            )


    # PTM
    if reading.PTM is not None:
        if reading.PTM > 250:
            alerts.append(
                ("MEDIUM", "PTM élevée")
            )


    # Débit sang
    if reading.Debit_sang is not None:
        if reading.Debit_sang < 200:
            alerts.append(
                ("HIGH", "Débit sanguin faible")
            )


    return alerts