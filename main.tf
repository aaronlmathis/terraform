provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Webserver" {
  ami               = "ami-00402f0bdf4996822"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "ansible"  # Remove this line if SSH access is not needed
  vpc_security_group_ids = ["sg-00210c164f22a8dc2"]
  
  user_data = <<-EOF
              #!/bin/bash
              # Update the system
              sudo apt-get update -y

              # Install required packages
              sudo apt-get install -y git python3 python3-pip python3-venv nginx

              # Create a virtual environment
              python3 -m venv /home/debian/flaskapp/venv

              # Activate the virtual environment
              source /home/debian/flaskapp/venv/bin/activate

              # Install Gunicorn in the virtual environment
              pip install gunicorn

              # Clone the GitHub repository
              git clone https://github.com/aaronlmathis/flaskapp.git /home/debian/flaskapp

              # Change directory to the app directory
              cd /home/debian/flaskapp

              # Install Python dependencies inside the virtual environment
              pip install -r requirements.txt

              # Set up Gunicorn to serve the Flask app using the virtual environment
              /home/debian/flaskapp/venv/bin/gunicorn --workers 3 --bind unix:/home/debian/flaskapp/flaskapp.sock -m 007 app:app --daemon

              # Configure Nginx to reverse proxy to Gunicorn
              sudo bash -c 'cat > /etc/nginx/sites-available/flaskapp << EOF
              server {
                  listen 80;
                  server_name _;

                  location / {
                      include proxy_params;
                      proxy_pass http://unix:/home/debian/flaskapp/flaskapp.sock;
                  }
              }
              EOF'

              # Enable the Nginx configuration and restart the service
              sudo ln -s /etc/nginx/sites-available/flaskapp /etc/nginx/sites-enabled
              sudo nginx -t
              sudo systemctl restart nginx

              EOF

  tags = {
    Name = "Terraform-Debian-Flask-Server"
  }
}
