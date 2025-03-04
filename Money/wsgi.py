import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get the Flask environment from environment variable, default to development
flask_env = os.getenv('FLASK_ENV', 'development')

from app import create_app
application = create_app(flask_env)

if __name__ == '__main__':
    # In development, enable debug mode
    debug = flask_env == 'development'
    application.run(debug=debug)