from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('api/', include('api.urls')),  # Delegate API-related routes to the api app
    path('admin/', admin.site.urls),  # Django admin route (if needed)
    # Add other global paths or include other apps' URLs as needed
]
