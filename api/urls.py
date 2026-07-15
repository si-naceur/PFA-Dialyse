from django.urls import path
from api import views
app_name = "api"

urlpatterns = [
    path('monitoring/', views.real_monitoring, name='real_monitoring'),
    path("push/", views.receive_measurements, name="receive_measurements"),
#path("ia-conseil/", views.ia_conseil, name="ia_conseil"),
    path("seance/debit/", views.get_debit, name="seance-debit"),
     # ── API agent n8n ─────────────────────────────────────────
    path("agent/resume-seance/",
         views.agent_resume_seance,
         name="agent_resume_seance"),
    path("agent/email-seance/",
         views.agent_email_seance, 
            name="agent_email_seance"),
     

]


