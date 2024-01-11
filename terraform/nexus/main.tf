provider "aws" {
  region    = "eu-north-1"
}


# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {

  tags    = {
    Name  = "default vpc"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}


# create default subnet if one does not exit
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags   = {
    Name = "default subnet"
  }
}


# create security group for the ec2 instance
resource "aws_security_group" "nexus_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 8081, 5500 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  # allow access on port 8080
  ingress {
    description      = "http proxy access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # allow access on port 22
  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # allow access on port 550
  ingress {
    description      = "ssh access"
    from_port        = 5500
    to_port          = 5500
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "nexus server security group"
  }
}

resource "tls_private_key" "nexus_private_key" {
  algorithm = "RSA"
  rsa_bits = 4096

  provisioner "local-exec" {
    command = "echo '${self.public_key_pem}' > ./pubkey.pem"
  }

}

resource "aws_key_pair" "nexus_key" {
  key_name = "nexus"
  public_key = tls_private_key.nexus_private_key.public_key_openssh
  
  provisioner "local-exec" {
    command = "echo '${tls_private_key.nexus_private_key.private_key_pem}' > ./private-key.pem"
  }
}

# launch the ec2 instance and install website
resource "aws_instance" "nexus" {
  ami                    = "ami-0014ce3e52359afbd"
  instance_type          = "t3.medium"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.nexus_security_group.id]
  key_name               = aws_key_pair.nexus_key.key_name
  # user_data            = file("install_nexus.sh")

  tags = {
    Name = "nexus server"
  }
}


# an empty resource block
# resource "null_resource" "name" {

#   # ssh into the ec2 instance 
#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file("/home/administrator/SubscriptionService/terraform/nexus/private-key.pem")
#     host        = aws_instance.nexus.public_dns
#   }

#   # copy the install_nexus.sh file from your computer to the ec2 instance 
#   provisioner "file" {
#     source      = "./install_nexus.sh"
#     destination = "/tmp/install_nexus.sh"
#   }

#   # set permissions and run the install_nexus.sh file
#   provisioner "remote-exec" {
#     inline = [
#         "sudo chmod +x /tmp/install_nexus.sh",
#         "sh /tmp/install_nexus.sh"
#     ]
#   }

#   # wait for ec2 to be created
#   depends_on = [aws_instance.nexus]
# }
