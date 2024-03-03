import time
import logging
import json
import os
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from dotenv import load_dotenv
from openai import OpenAI
import gevent
from gevent import Timeout

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
        logging.info("Creating a new OpenAI thread.")
        thread = client.beta.threads.create()
        client.beta.threads.messages.create(thread_id=thread.id, role="user", content=event_title)
        run = client.beta.threads.runs.create(thread_id=thread.id, assistant_id='asst_OprZ49gQ0ckkTF8GoHKwtXDy')

        timeout = 30  # seconds
        start_time = time.time()

        status_checked = False
        while not status_checked:
            if time.time() - start_time > timeout:
                logging.error("Timeout waiting for OpenAI run to complete.")
                response_container['response'] = "Timeout waiting for OpenAI to respond."
                return

            updated_run = client.beta.threads.runs.retrieve(thread_id=thread.id, run_id=run.id)
            logging.info(updated_run)
            time.sleep(1)
            if updated_run.status in ['completed', 'failed']:
                status_checked = True

        messages_response = client.beta.threads.messages.list(thread_id=thread.id)
        if not messages_response.data:
            logging.error("No messages found in the OpenAI thread response.")
            response_container['response'] = 'No messages found in the response from OpenAI.'
            return

        for message in reversed(messages_response.data):
            logging.info(message)
            # Check if the message has the expected structure and content.
            if message.role == 'assistant' and hasattr(message.content[0], 'text'):
                # Directly access the 'value' if it exists.
                response_value = getattr(message.content[0].text, 'value', None)
                if response_value:
                    response_container['response'] = response_value
                    logging.info("Successfully processed the OpenAI thread response.")
                    return

        logging.info("No valid assistant message found in OpenAI thread response.")
        response_container['response'] = 'No valid response received from the assistant.'
    except Exception as e:
        logging.error(f"Exception occurred during OpenAI request handling: {e}", exc_info=True)
        response_container['response'] = f"An error occurred: {str(e)}"

@csrf_exempt
def home(request):
    logging.info(f"Request received: {request.method}")
    if request.method == 'POST':
        # Check if the request is from Kairos
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        if "Kairos" not in user_agent:
            return HttpResponse("Forbidden", status=403)

        try:
            data = json.loads(request.body)
            logging.info(f"Received request: {data}")
            response_container = {}

            # Set a timeout for the OpenAI request handling
            timeout_seconds = 45
            api_greenlet = gevent.spawn(handle_openai_request, data, response_container)
            try:
                with Timeout(timeout_seconds):
                    api_greenlet.join()
            except Timeout:
                return HttpResponse("Request timed out.", status=504)

            return JsonResponse(response_container)
        except json.JSONDecodeError:
            return HttpResponse("Invalid JSON", status=400)
        except Exception as e:
            error_message = f"Error processing request: {str(e)}"
            logging.error(error_message)
            return HttpResponse(error_message, status=500)
    else:
        return HttpResponse("Method Not Allowed", status=405)