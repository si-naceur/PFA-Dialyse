import json

from django.http import JsonResponse
from django.shortcuts import render
from django.db.models import Q
from accounts.models import User, UserActivity
from accounts.decorator import app_login_required, role_required
from django.utils import timezone
from datetime import timedelta
from django.views.decorators.csrf import csrf_exempt
from machines.models import MachineTypeModule
from monitoring.models import LiveMeasurement
from seances.models import Seance


@app_login_required
@role_required("Admin", redirect_to="accounts:error")
def dashboard(request):
    current_user = request.current_user

    # KPIs (comme avant)
    kpi_doctors = User.objects.filter(role__name__in=["Docteur", "Admin"]).count()
    kpi_nurses = User.objects.filter(role__name__iexact="Infirmier").count()
    kpi_machines_total = 0
    kpi_machines_available = 0
    limit = timezone.now() - timedelta(minutes=5)
    kpi_active_users = User.objects.filter(etat=True).count()

    # GET params (on garde day et on ajoute q/role/sort)
    selected_day = (request.GET.get("day") or "").strip()
    q = (request.GET.get("q") or "").strip()
    role_filter = (request.GET.get("role") or "").strip()
    sort = (request.GET.get("sort") or "-login_at").strip()
    status = (request.GET.get("status") or "").strip()   # <-- AJOUT

    allowed_sorts = {"login_at", "-login_at", "username", "-username"}
    if sort not in allowed_sorts:
        sort = "-login_at"

    # Base queryset
    qs = UserActivity.objects.select_related("user", "user__role")

    # Filtre par date (comme avant)
    if selected_day:
        qs = qs.filter(login_at__date=selected_day)

    # Recherche utilisateur (username ou email)
    if q:
        qs = qs.filter(
            Q(user__username__icontains=q) |
            Q(user__email__icontains=q)
        )

    # Filtre rôle (liste Docteur/Infirmier)
    if role_filter in ("Docteur", "Infirmier", "Admin"):
        qs = qs.filter(user__role__name__iexact=role_filter)
    
    
    if sort in ("username", "-username"):
        prefix = "-" if sort.startswith("-") else ""
        qs = qs.order_by(f"{prefix}user__username", "-login_at")
    else:
        qs = qs.order_by(sort)
    
    if status == "ongoing":

        qs = qs.filter(logout_at__isnull=True)

    activity_rows = qs[:50]

    context = {
        "current_user": current_user,
        "kpi_doctors": kpi_doctors,
        "kpi_nurses": kpi_nurses,
        "kpi_machines_total": kpi_machines_total,
        "kpi_machines_available": kpi_machines_available,
        "kpi_active_users": kpi_active_users,
        "activity_rows": activity_rows,
        # pour garder les valeurs dans dashboard.html
        "selected_day": selected_day,
        "q": q,
        "role_filter": role_filter,
        "sort": sort,
        "status":status,
    }
    return render(request, "dashboard.html", context)


@app_login_required
@role_required("Admin", "Docteur", "Infirmier", redirect_to="accounts:error")
def surveillance_view(request):
    current_user = request.current_user
    active_sessions = Seance.objects.filter(status="en cours") \
          .select_related("patient", "machine")
    return render(request, "surveillance.html", {"current_user": current_user ,"sessions": active_sessions})

@csrf_exempt
def push_measurements(request):
    data = json.loads(request.body)

    machine_id = data["machine_id"]

    seance = Seance.objects.filter(
        machine__machine_id=machine_id,
        status="en cours"
    ).first()

    if not seance:
        return JsonResponse({"error": "No active session"}, status=404)

    for m in data["measurements"]:
        try:
            module = MachineTypeModule.objects.get(
                machine_type=seance.machine.type,
                code=m["code"]
            )

            LiveMeasurement.objects.create(
                seance=seance,
                module=module,
                value=m.get("value"),
                unit=m.get("unit", ""),
                confidence=m.get("confidence")
            )
        except MachineTypeModule.DoesNotExist:
            continue

    return JsonResponse({"status": "ok"})