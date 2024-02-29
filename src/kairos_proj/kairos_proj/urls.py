"""
URL configuration for kairos_proj project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from django.http import HttpResponse
import os
from django.http import JsonResponse
from openai import OpenAI
from dotenv import load_dotenv
from django.views.decorators.csrf import csrf_exempt
import json
from django.views.decorators.http import require_http_methods

# Load environment variables
dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path)

@csrf_exempt
def home(request):
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        return HttpResponse("API key is not set.", status=500)

    client = OpenAI(api_key=api_key)

    if request.method == 'GET':
        # GET request: Continue handling GPT interaction
        user_message = request.GET.get('message', 'Hello, World!')
        try:
            completion = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are an assistant."},
                    {"role": "user", "content": user_message}
                ]
            )
            gpt_response = completion.choices[0].message.content
            return JsonResponse({'response': gpt_response})
        except Exception as e:
            return HttpResponse(f"Error: {str(e)}", status=500)

    elif request.method == 'POST':
        # POST request: Process event data and interact with GPT
        try:
            data = json.loads(request.body)
            event_title = data.get('title', '')  # Use default empty string if not provided

            # Interact with the OpenAI API using the event title
            try:
                completion = client.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=[
                        {"role": "system", "content": "You are an assistant."},
                        {"role": "user", "content": event_title}
                    ]
                )
                # Return the AI's response related to the event title
                gpt_response = completion.choices[0].message.content
                return JsonResponse({'response': gpt_response})
            except Exception as e:
                return HttpResponse(f"Error interacting with OpenAI: {str(e)}", status=500)

        except json.JSONDecodeError:
            return HttpResponse("Invalid JSON", status=400)
        except Exception as e:
            return HttpResponse(f"Error processing request: {str(e)}", status=500)

urlpatterns = [
    path('', home, name='home'),
]
