from django.urls import path
from . import views
app_name = "monitoring"
urlpatterns = [
    path('', views.dashboard, name='dashboard'),
    path('surveillance/', views.surveillance_view, name='surveillance'),
    path("api/push/", views.push_measurements, name="push_measurements"),
]