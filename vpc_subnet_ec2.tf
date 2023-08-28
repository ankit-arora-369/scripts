provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

resource "aws_vpc" "main" {
  cidr_block = "172.20.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.20.10.0/24"
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "172.20.20.0/24"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_security_group" "allow_private_access" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private_subnet.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins_ansible_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with your desired Debian AMI
  instance_type = "t2.micro"  # Replace with your desired instance type
  subnet_id     = aws_subnet.private_subnet.id
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y openjdk-11-jdk  # Installing Java for Jenkins
              apt-get install -y ansible
              wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
              sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
              apt-get update
              apt-get install -y jenkins
              systemctl start jenkins
              systemctl enable jenkins
              EOF

  tags = {
    Name = "Jenkins-Ansible-Instance"
  }

  security_groups = [aws_security_group.allow_private_access.id]
}


