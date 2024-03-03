from django.urls import path
from . import views

urlpatterns = [
    path('your-endpoint/', views.home, name='api_home'),
    # Define more API endpoints as needed
]
