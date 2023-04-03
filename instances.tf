# Infrastructure code with Terraform to run 10 Ubuntu 22.04 machines with 1 Core and 1GB RAM on AWS, default VPC

provider "aws" {
  region = "us-east-2"
}

resource "aws_key_pair" "public_key" {
  key_name   = "public_key"
  public_key = file(var.PUB_KEY)
}

resource "aws_instance" "laravel" {
  ami                    = "ami-0a695f0d95cefc163"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.public_key.key_name
  availability_zone      = "us-east-2a"
  vpc_security_group_ids = [aws_security_group.laravel-SG.id]
  for_each = toset(["web1", "web2", "web3"])
   tags = {
     Name = "${each.key}"
   }

  provisioner "file" {
    source      = "web-server.sh"
    destination = "/tmp/web-server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/web-server.sh",
      "sudo /tmp/web-server.sh"
    ]
  }

  connection {
    user        = var.USER
    private_key = file(var.PRI_KEY)
    host        = self.public_ip
  }

}

resource "aws_security_group" "laravel-SG" {

  name = "laravel-SG"

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "laravel-SG"
  }
}

variable "PRI_KEY" {
  default = "laravel"
}
variable "PUB_KEY" {
  default = "laravel.pub"
}
variable "USER" {
  default = "ubuntu"
}

