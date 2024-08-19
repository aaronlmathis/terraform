provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Webserver" {
  ami               = "ami-00402f0bdf4996822"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "Terraform"
  vpc_security_group_ids = ["sg-00210c164f22a8dc2"]
  
  user_data = <<-EOT
              #!/bin/bash
              # Update the system
              sudo apt-get update -y

              # Install required packages
              sudo apt-get install -y git python3 python3-pip python3-venv nginx

              # Clone the GitHub repository
              git clone https://github.com/aaronlmathis/flaskapp.git /home/admin/flaskapp

              # Create a virtual environment
              python3 -m venv /home/admin/flaskapp/.venv

              # Activate the virtual environment
              source /home/admin/flaskapp/.venv/bin/activate

              # Install Gunicorn in the virtual environment
              pip install gunicorn

              # Change directory to the app directory
              cd /home/admin/flaskapp

              # Install Python dependencies inside the virtual environment
              pip install -r requirements.txt

              # Set up Gunicorn to serve the Flask app using the virtual environment
              /home/admin/flaskapp/.venv/bin/gunicorn --workers 3 --bind unix:/home/admin/flaskapp/flaskapp.sock -m 007 "website:create_app()" --daemon
              
              # Wait for Gunicorn to start and create the socket file
              sleep 10
              
              # Set the correct permissions on the Unix socket
              sudo chmod 666 /home/admin/flaskapp/flaskapp.sock

              # Configure Nginx to reverse proxy to Gunicorn
              sudo tee /etc/nginx/sites-available/flaskapp > /dev/null <<EONGINX
              server {
                  listen 80;
                  server_name _;

                  location / {
                      include proxy_params;
                      proxy_pass http://unix:/home/admin/flaskapp/flaskapp.sock;
                  }
              }
              EONGINX

              # Enable the Nginx configuration and restart the service
              sudo rm /etc/nginx/sites-enabled/default
              sudo ln -s /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled
              sudo nginx -t
              sudo systemctl restart nginx

              EOT

  tags = {
    Name = "Terraform-Debian-Flask-Server"
  }
}
