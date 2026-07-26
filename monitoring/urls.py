from django.urls import path
from . import views


app_name="monitoring"


urlpatterns=[

    path(
        '',
        views.dashboard,
        name="dashboard"
    ),


    path(
        'surveillance/',
        views.surveillance_view,
        name="surveillance"
    ),
    path(
    'live-data/',
    views.live_data,
    name="live_data"
),
path(
    "alert/<uuid:alert_id>/ack/",
    views.ack_alert,
    name="ack_alert"
),
]