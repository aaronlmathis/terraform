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
              
              # Change ownership of the Flask app directory
              sudo chown -R admin:admin /home/admin/flaskapp
              
              # Create a virtual environment
              python3 -m venv /home/admin/flaskapp/.venv

              # Install Gunicorn in the virtual environment
              /home/admin/flaskapp/.venv/bin/pip install gunicorn

              # Install Python dependencies inside the virtual environment
              /home/admin/flaskapp/.venv/bin/pip install -r /home/admin/flaskapp/requirements.txt

              # Create Gunicorn systemd service file
              sudo tee /etc/systemd/system/flask_app.service > /dev/null <<EOF
              [Unit]
              Description=Gunicorn instance to serve Flask app
              After=network.target

              [Service]
              User=admin
              Group=admin
              WorkingDirectory=/home/admin/flaskapp
              Environment="PATH=/home/admin/flaskapp/.venv/bin"
              ExecStart=/home/admin/flaskapp/.venv/bin/gunicorn --workers 3 --bind unix:/home/admin/flaskapp/flaskapp.sock website:create_app

              [Install]
              WantedBy=multi-user.target
              EOF

              # Reload systemd to read the new service file
              sudo systemctl daemon-reload

              # Start and enable Gunicorn service
              sudo systemctl start flask_app
              sudo systemctl enable flask_app

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