from django.urls import path
from . import views

urlpatterns = [
    path('assistant/', views.home, name='gpt4'),
    # Define more API endpoints as needed
]
