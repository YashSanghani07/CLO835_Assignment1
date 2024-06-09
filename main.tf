provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_account_id" {
  default = "<YOUR_AWS_ACCOUNT_ID>"
}

resource "aws_ecr_repository" "webapp" {
  name = "webapp"
}

resource "aws_ecr_repository" "mysql" {
  name = "mysql"
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 8081
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_instance" {
  count         = 3
  ami           = "ami-0abcdef1234567890"
  instance_type = "t2.micro"
  key_name      = "your-key-pair" # Update with your key pair name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    amazon-linux-extras install docker -y
    service docker start
    usermod -a -G docker ec2-user

    docker login -u AWS -p $(aws ecr get-login-password --region ${var.aws_region}) ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    docker run --name webapp --network app-network -e COLOR=${count.index} -p 808${count.index+1}:8080 ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/webapp:latest

    docker run --name mysql --network app-network -e MYSQL_ROOT_PASSWORD=rootpassword -e MYSQL_DATABASE=webapp -d ${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/mysql:latest
  EOF

  tags = {
    Name = "WebAppInstance-${count.index + 1}"
  }
}
