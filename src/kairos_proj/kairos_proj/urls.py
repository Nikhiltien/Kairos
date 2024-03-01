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

from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
import json
import os
from dotenv import load_dotenv
from openai import OpenAI
from django.urls import path
import gevent
import logging

logging.basicConfig(level=logging.INFO, filename='logs.log', filemode='a',
                    format='%(name)s - %(levelname)s - %(message)s')

# Load environment variables
dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path)

def handle_openai_request(data, response_container):
    api_key = os.getenv("OPENAI_API_KEY")
    client = OpenAI(api_key=api_key)
    event_title = data.get('title', '')

    # Create a new thread for the conversation in OpenAI context
    thread = client.beta.threads.create()

    # Add the user's message to the thread
    client.beta.threads.messages.create(
        thread_id=thread.id,
        role="user",
        content=event_title
    )

    # Start the assistant run and wait for its completion
    run = client.beta.threads.runs.create(
        thread_id=thread.id,
        assistant_id='asst_OprZ49gQ0ckkTF8GoHKwtXDy'
    )

    while True:
        updated_run = client.beta.threads.runs.retrieve(thread_id=thread.id, run_id=run.id)
        if updated_run.status in ['completed', 'failed']:
            break

    # Retrieve the final messages from the thread
    messages_response = client.beta.threads.messages.list(thread_id=thread.id)

    if messages_response.data:
        for message in reversed(messages_response.data):  # Iterate in reverse to get the most recent message first
            if message.role == 'assistant':  # Check if the message is from the assistant
                # Assuming message.content is a list, check the first item if it exists
                if hasattr(message, 'content') and isinstance(message.content, list) and message.content:
                    content_item = message.content[0]
                    if hasattr(content_item, 'text') and hasattr(content_item.text, 'value'):
                        # Store the assistant's message in the response container and break
                        response_container['response'] = content_item.text.value
                        break
                else:
                    logging.error("Message content is not a list or is missing.")
                break  # Break after processing the most recent assistant's message
    else:
        logging.error("No messages found in the response.")

@csrf_exempt
def home(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            response_container = {}

            # Use gevent.spawn to offload the OpenAI API call to a greenlet
            api_greenlet = gevent.spawn(handle_openai_request, data, response_container)
            api_greenlet.join()  # Wait for the greenlet to finish

            return JsonResponse(response_container)
        except json.JSONDecodeError:
            return HttpResponse("Invalid JSON", status=400)
        except Exception as e:
            error_message = f"Error processing request: {str(e)}"
            return HttpResponse(error_message, status=500)

urlpatterns = [
    path('', home, name='home'),
]

