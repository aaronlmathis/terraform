
provider "aws" {
  region     = "us-east-1"


}

resource "aws_instance" "Webserver" {
  ami               = "ami-00402f0bdf4996822"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"

}
