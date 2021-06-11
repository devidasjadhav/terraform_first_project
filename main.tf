provider "aws" {
  region  = "ap-south-1"
}

resource "aws_vpc" "base_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name: "base-vpc"
  }
}

resource "aws_subnet" "base_subnet" {
  vpc_id = aws_vpc.base_vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name: "base-subnet"
  }
}

resource "aws_internet_gateway" "base_gateway" {
  vpc_id = aws_vpc.base_vpc.id

  tags = { 
    Name: "base-gateway" 
  }
}

resource "aws_route_table" "base_route_table" {
  vpc_id = aws_vpc.base_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.base_gateway.id
  }

  tags = {
    Name: "base-route-table"
  }
}

resource "aws_route_table_association" "base_association" {
  subnet_id = aws_subnet.base_subnet.id
  route_table_id = aws_route_table.base_route_table.id
}

resource "aws_security_group" "base_security_group" {
  name = "base-security-group"
  vpc_id = aws_vpc.base_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80 
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name: "base-security-group"
  }

}
data "aws_ami" "ubuntu_focal" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  name_regex = "ubuntu-focal-20.04-amd64-server*"
}

resource "aws_key_pair" "ssh_key" {
  key_name = "base_server_key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "base_server" {
  ami = data.aws_ami.ubuntu_focal.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.base_subnet.id
  vpc_security_group_ids = [aws_security_group.base_security_group.id]
  availability_zone = "ap-south-1b"
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh_key.key_name
  user_data = file("start_script.sh")

  tags = {
    Name: "base-ubuntu-server"
  }
}

output "ec2_public_ip" {
  value = aws_instance.base_server.public_ip
}
