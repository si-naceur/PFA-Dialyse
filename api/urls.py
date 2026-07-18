from django.urls import path
from . import views


app_name = "api"


urlpatterns = [

    path(
        "push/",
        views.push_measurement,
        name="push_measurement"
    ),


    path(
        "real-monitoring/",
        views.real_monitoring,
        name="real_monitoring"
    ),

]