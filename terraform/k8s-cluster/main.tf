terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.5.0"
    }
    tls = {
        source = "hashicorp/tls"
        version = "4.0.4"
  }
  }
}

provider "aws" {
  region= "eu-north-1"
}

# custom vpc

resource "aws_vpc" "kubeadm_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "kubeadm_vpc"
  }
}

#subnet

resource "aws_subnet" "kubeadm_subnet" {
  vpc_id = aws_vpc.kubeadm_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "kubeadm_subnet"
  }
}

#igw

resource "aws_internet_gateway" "kubeadm_igw" {
  vpc_id = aws_vpc.kubeadm_vpc.id

  tags = {
    Name = "kubeadm_igw"
  }

}

#custom route table 

resource "aws_route_table" "kubeadm_rt" {
  vpc_id = aws_vpc.kubeadm_vpc.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubeadm_igw.id
  }

  tags = {
    Name = "kubeadm_rt"
  }

}

#ART with subnet

resource "aws_route_table_association" "kubeadm_art" {
  subnet_id = aws_subnet.kubeadm_subnet.id
  route_table_id = aws_route_table.kubeadm_rt.id

}

#sg
#common ports (ssh,http,https)
resource "aws_security_group" "kubeadm_sg_common" {
  name = "kubeadm_sg_common"

  tags = {
  Name = "kubeadm_sg_common"

  }

  ingress {
    description     = "Allow HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Allow SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks      = ["0.0.0.0/0"] 
    ipv6_cidr_blocks = ["::/0"]
  }
}
  #control plane ports
resource "aws_security_group" "kubeadm_sg_control_plane" {
  name = "kubeadm_sg_control_plane"

  tags = {
  Name = "kubeadm_sg_control_plane"

  }

  ingress {
    description     = "Api service"
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description     = "KubeAPI"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description     = "kube-scheduler"
    from_port       = 10259
    to_port         = 10259
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description     = "kube-controller-manager"
    from_port       = 10257
    to_port         = 10257
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Etcd server client API"
    from_port       = 2379
    to_port         = 2380
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
# worker node ports
resource "aws_security_group" "kubeadm_sg_worker_nodes" {

  ingress {
    description     = "KubeAPI"
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description     = "NodePorts"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kubeadm_sg_flannel" {
  
  tags = {
    Name = "kubeadm_sg_flannel"
  }

  ingress = {
    description= "udp backend"
    from_port       = 8285
    to_port         = 8285
    protocol        = "udp"
    cidr_blocks     =["0.0.0.0/0"]
  }
}

resource "tls_private_key" "kubeadm_private_key" {
  algorithm = "RSA"
  rsa_bits = 4096

  provisioner "local-exec" {
    command = "echo '${self.public_key_pem}' > ./pubkey.pem"
  }

}

resource "aws_key_pair" "kubeadm_key" {
  key_name = var.kubeadm_key_name
  public_key = tls_private_key.kubeadm_private_key.public_key_openssh
  
  provisioner "local-exec" {
    command = "echo '${tls_private_key.kubeadm_private_key.private_key_pem}' > ./private-key.pem"
  }
  }

  resource "aws_instance" "kubeadm_sg_control_plane" {
    instance_type = "t3.micro"
    ami           = var.kubeadm_ami 
    key_name      = aws_key_pair.kubeadm_key.key_name
    associate_public_ip_address = true
    security_groups = [
        aws_security_group.kubeadm_sg_control_plane,
        aws_security_group.kubeadm_sg_common,
        aws_security_group.kubeadm_sg_flannel,
    ]


    root_block_device {
      
      volume_size = 14
      volume_type = "gp2"
    }

    tags = {
      Name="Kubeadm ControlPanel"
    }

    provisioner "local-exec" {
      command = "echo 'master ${self.public_ip}' >> ./files/hosts"
    }


  }