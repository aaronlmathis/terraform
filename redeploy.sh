#!/bin/bash

# Navigate to the app directory
cd /home/admin/flaskapp

# Pull the latest code
git pull origin main

# Activate the virtual environment
source .venv/bin/activate

# Install any new dependencies
pip install -r requirements.txt

# Restart Gunicorn
sudo systemctl restart gunicorn

# Reload Nginx if needed
sudo nginx -t && sudo systemctl reload nginx
