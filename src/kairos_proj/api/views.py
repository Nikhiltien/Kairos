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
import logging
import json
import os
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from dotenv import load_dotenv
from openai import OpenAI
from django.urls import path
import gevent

# Basic logging configuration
logging.basicConfig(level=logging.INFO, filename='logs.log', filemode='a',
                    format='%(name)s - %(levelname)s - %(message)s')

# Load environment variables
dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path)

def handle_openai_request(data, response_container):
    api_key = os.getenv("OPENAI_API_KEY")
    client = OpenAI(api_key=api_key)
    event_title = data.get('title', '')
    
    try:
        # Attempt to create a new thread and interact with it
        thread = client.beta.threads.create()
        client.beta.threads.messages.create(thread_id=thread.id, role="user", content=event_title)
        run = client.beta.threads.runs.create(thread_id=thread.id, assistant_id='asst_OprZ49gQ0ckkTF8GoHKwtXDy')

        while True:
            updated_run = client.beta.threads.runs.retrieve(thread_id=thread.id, run_id=run.id)
            if updated_run.status in ['completed', 'failed']:
                break

        messages_response = client.beta.threads.messages.list(thread_id=thread.id)

        if messages_response.data:
            for message in reversed(messages_response.data):
                if message.role == 'assistant' and hasattr(message, 'content') and isinstance(message.content, list) and message.content:
                    content_item = message.content[0]
                    if hasattr(content_item, 'text') and hasattr(content_item.text, 'value'):
                        response_container['response'] = content_item.text.value
                        return  # Exit after setting the response
            # Fallback if no valid assistant message is found
            response_container['response'] = 'No valid response received from the assistant.'
        else:
            logging.error("No messages found in the response.")
            response_container['response'] = 'No messages found in the response from OpenAI.'
    except Exception as e:
        logging.error(f"Exception in handle_openai_request: {str(e)}")
        response_container['response'] = f"An error occurred: {str(e)}"

@csrf_exempt
def home(request):
    logging.info(request)
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            logging.info(f"received request: {data}")
            response_container = {'response': 'Processing failed. Please try again.'}  # Default error response

            api_greenlet = gevent.spawn(handle_openai_request, data, response_container)
            api_greenlet.join()

            return JsonResponse(response_container)
        except json.JSONDecodeError:
            return HttpResponse("Invalid JSON", status=400)
        except Exception as e:
            error_message = f"Error processing request: {str(e)}"
            return HttpResponse(error_message, status=500)
    else:
        return HttpResponse("Method Not Allowed", status=405)

urlpatterns = [
    path('', home, name='home'),
]

