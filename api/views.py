import json

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from machines.models import Machine
from seances.models import Seance
from monitoring.models import LiveMeasurement


@csrf_exempt
def push_measurement(request):

    if request.method != "POST":
        return JsonResponse(
            {"error": "POST required"},
            status=405
        )

    try:
        data = json.loads(request.body)

        machine_id = data.get("machine_id")

        machine = Machine.objects.get(
            machine_id=machine_id
        )


        seance = Seance.objects.filter(
            machine=machine,
            status="en cours"
        ).first()


        if not seance:
            return JsonResponse(
                {
                    "error": "No active seance for this machine"
                },
                status=400
            )


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
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.hashers import check_password
from accounts.models import User
import json


@csrf_exempt
def mobile_login(request):

    if request.method != "POST":
        return JsonResponse(
            {"success": False, "message": "POST only"},
            status=405
        )

    try:
        body = json.loads(request.body)

        username = body.get("username", "").strip()
        password = body.get("password", "")

        user = User.objects.filter(username=username).first()

        if user is None:
            return JsonResponse({
                "success": False,
                "message": "Invalid username"
            })

        if not check_password(password, user.password):
            return JsonResponse({
                "success": False,
                "message": "Invalid password"
            })

        user.etat = True
        user.save()
        request.session['app_user_id'] = user.id

        return JsonResponse({
            "success": True,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "role": user.role.name,
            }
        })

    except Exception as e:
        return JsonResponse({
            "success": False,
            "message": str(e)
        }, status=500)