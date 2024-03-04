import os
import time
import logging
from openai import OpenAI
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path)
api_key = os.getenv("OPENAI_API_KEY")
print(api_key)
        
class GPT:
    def __init__(self, model=None):
        self.logger = logging.getLogger(self.__class__.__name__)
        self.client = OpenAI(api_key=api_key)
        self.model = model or "gpt-3.5-turbo"  # Default model if not provided
        self.timeout = 30

    def create_thread_and_run(self, event_title):
        try:
            thread = self.client.beta.threads.create()
            self.client.beta.threads.messages.create(thread_id=thread.id, role="user", content=event_title)
            return self.client.beta.threads.runs.create(thread_id=thread.id, assistant_id='asst_OprZ49gQ0ckkTF8GoHKwtXDy')
        except Exception as e:
            self.logger.error(f"Failed to create thread and run: {e}")
            return None

    def check_run_status(self, thread_id, run_id):
        start_time = time.time()
        try:
            while time.time() - start_time < self.timeout:
                updated_run = self.client.beta.threads.runs.retrieve(thread_id=thread_id, run_id=run_id)
                if updated_run.status in ['completed', 'failed']:
                    return updated_run
                time.sleep(1)
        except Exception as e:
            self.logger.error(f"Error checking run status: {e}")
        self.logger.error("Timeout waiting for OpenAI run to complete.")
        return None

    def get_response_from_thread(self, thread_id):
        try:
            messages_response = self.client.beta.threads.messages.list(thread_id=thread_id)
            for message in reversed(messages_response.data):
                if message.role == 'assistant' and 'text' in message.content[0]:
                    return message.content[0]['text'].get('value', None)
        except Exception as e:
            self.logger.error(f"Failed to get response from thread: {e}")
        return None

    def handle_request(self, event_title):
        response = {}
        run = self.create_thread_and_run(event_title)
        if run:
            updated_run = self.check_run_status(run.thread_id, run.id)
            if updated_run and updated_run.status == 'completed':
                response_value = self.get_response_from_thread(run.thread_id)
                response['response'] = response_value if response_value else "No valid response received."
            else:
                response['response'] = "Failed to complete the processing."
        else:
            response['response'] = "Failed to initiate the processing."
        return response
    
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    logger = logging.getLogger(__name__)
    logger.info("Starting GPT class functionality test...")

    # Initialize GPT class with a specific model (or default if not specified).
    model_name = "gpt-3.5-turbo"  # Example model, replace with the intended one.
    gpt_instance = GPT(model=model_name)

    # Define an example event title to process.
    event_title = "What is the impact of AI on society?"

    # Handle the request using the GPT instance and capture the response.
    try:
        logger.info("Processing event: " + event_title)
        response = gpt_instance.handle_request(event_title)
        if response and 'response' in response:
            logger.info("Received response: " + response['response'])
        else:
            logger.error("No response received.")
    except Exception as e:
        logger.error(f"Error during GPT class functionality test: {str(e)}")