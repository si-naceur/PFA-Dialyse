def check_thresholds(reading):
    alerts = []

    # PA
    if reading.PA is not None:
        if reading.PA < 70:
            alerts.append(
                ("RED", "Pression artérielle critique : trop basse")
            )
        elif reading.PA > 200:
            alerts.append(
                ("RED", "Pression artérielle critique : trop élevée")
            )
        elif reading.PA < 90:
            alerts.append(
                ("YELLOW", "Pression artérielle basse")
            )
        elif reading.PA > 180:
            alerts.append(
                ("YELLOW", "Pression artérielle élevée")
            )

    # PV
    if reading.PV is not None:
        if reading.PV < 30:
            alerts.append(
                ("RED", "Pression veineuse critique : trop basse")
            )
        elif reading.PV > 280:
            alerts.append(
                ("RED", "Pression veineuse critique : trop élevée")
            )
        elif reading.PV < 50:
            alerts.append(
                ("YELLOW", "Pression veineuse basse")
            )
        elif reading.PV > 250:
            alerts.append(
                ("YELLOW", "Pression veineuse élevée")
            )

    # PTM
    if reading.PTM is not None:
        if reading.PTM < -80:
            alerts.append(
                ("RED", "PTM critique : trop basse")
            )
        elif reading.PTM > 350:
            alerts.append(
                ("RED", "PTM critique : trop élevée")
            )
        elif reading.PTM < -50:
            alerts.append(
                ("YELLOW", "PTM basse")
            )
        elif reading.PTM > 300:
            alerts.append(
                ("YELLOW", "PTM élevée")
            )

    # Débit sanguin
    if reading.Debit_sang is not None:
        if reading.Debit_sang < 100:
            alerts.append(
                ("RED", "Débit sanguin critique : trop faible")
            )
        elif reading.Debit_sang > 450:
            alerts.append(
                ("RED", "Débit sanguin critique : trop élevé")
            )
        elif reading.Debit_sang < 150:
            alerts.append(
                ("YELLOW", "Débit sanguin faible")
            )
        elif reading.Debit_sang > 400:
            alerts.append(
                ("YELLOW", "Débit sanguin élevé")
            )

    # Taux UF
    if reading.Taux_UF is not None:
        if reading.Taux_UF > 1200:
            alerts.append(
                ("RED", "Taux UF critique : trop élevé")
            )
        elif reading.Taux_UF > 1000:
            alerts.append(
                ("YELLOW", "Taux UF élevé")
            )

    # Volume UF
    if reading.Volume_UF is not None:
        if reading.Volume_UF > 5000:
            alerts.append(
                ("RED", "Volume UF critique : trop élevé")
            )
        elif reading.Volume_UF > 4000:
            alerts.append(
                ("YELLOW", "Volume UF élevé")
            )

    # Héparine
    if reading.Heparine is not None:
        if reading.Heparine > 2500:
            alerts.append(
                ("RED", "Héparine critique : trop élevée")
            )
        elif reading.Heparine > 2000:
            alerts.append(
                ("YELLOW", "Héparine élevée")
            )

    return alerts