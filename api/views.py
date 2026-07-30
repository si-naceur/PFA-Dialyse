import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from machines.models import Machine
from seances.models import Seance
from monitoring.models import LiveMeasurement
from django.urls import path
from monitoring.views import push_measurement, real_monitoring


app_name = "api"


urlpatterns = [

    path(
        "push/",
        push_measurement,
        name="push_measurement"
    ),

    path(
        "real-monitoring/",
        real_monitoring,
        name="real_monitoring"
    ),

]


@csrf_exempt
def push_measurement(request):
    print("========== PUSH VIEW CALLED ==========")

    if request.method != "POST":
        return JsonResponse(
            {"error": "POST required"},
            status=405
        )

    try:
        data = json.loads(request.body)

        print("DATA RECEIVED:", data)

        machine_id = data.get("machine_id")

        print("MACHINE ID:", repr(machine_id))

        machine = Machine.objects.get(
            machine_id=machine_id
        )
       


        seance = Seance.objects.filter(
            machine=machine,
            status="En cours"
        ).first()


        if not seance:
            return JsonResponse(
                {
                    "error": "No active seance for this machine"
                },
                status=400
            )
        from django.conf import settings

        print("DATABASE:", settings.DATABASES["default"]["NAME"])


        measurement = LiveMeasurement.objects.create(
            

            seance=seance,

            Debit_sang=data.get("Qb"),
            Taux_UF=data.get("UF_rate"),
            PA=data.get("PA"),
            PTM=data.get("PTM"),
            PV=data.get("PV"),
            Volume_UF=data.get("UF_volume"),
            Heparine=data.get("Heparin"),

        )
        print("SAVED:", measurement.id)


        return JsonResponse(
            {
                "success": True,
                "id": measurement.id
            }
        )


    except Machine.DoesNotExist:

        return JsonResponse(
            {
                "error":"Machine not found"
            },
            status=404
        )


    except Exception as e:

        return JsonResponse(
            {
                "error":str(e)
            },
            status=500
        )



def real_monitoring(request):

    measurements = LiveMeasurement.objects.all().order_by("-timestamp")[:20]

    data = []

    for m in measurements:

        data.append({

            "machine": str(m.seance.machine),
            "Qb": m.Debit_sang,
            "PA": m.PA,
            "PTM": m.PTM,
            "PV": m.PV,
            "UF": m.Volume_UF,
            "time": m.timestamp

        })


    return JsonResponse({
        "measurements": data
    })