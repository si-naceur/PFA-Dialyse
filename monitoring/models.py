from django.db import models

# Create your models here.
import uuid
from seances.models import Seance
from machines.models import MachineTypeModule

class LiveMeasurement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    seance = models.ForeignKey(Seance, on_delete=models.CASCADE, related_name="readings")
    timestamp = models.DateTimeField()
    Debit_sang = models.FloatField(null=True)
    Taux_UF = models.FloatField(null=True)
    PA = models.FloatField(null=True)
    PTM = models.FloatField(null=True)
    PV= models.FloatField(null=True)
    Volume_UF = models.FloatField(null=True)
    Heparine = models.FloatField(null=True)

    class Meta:
        db_table = 'vital_readings'