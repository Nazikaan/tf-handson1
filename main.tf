# create vpc:
resource "aws_vpc" "handsone_vpc" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name      = "handsone_vpc"
    Team      = "DevOps"
    Env       = "handsone"
    ManagedBy = "Terraform"
  }
}

# create public-1a subnet in us-east-1a:
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.handsone_vpc.id
  cidr_block              = "10.0.0.0/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "public_1a_subnet"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

# create public-1f subnet in us-east-1f:
resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.handsone_vpc.id
  cidr_block              = "10.0.0.64/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name      = "public_1b_subnet"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

# create private-1a subnet in us-east-1a:
resource "aws_subnet" "private_1a" {
  vpc_id                  = aws_vpc.handsone_vpc.id
  cidr_block              = "10.0.0.128/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name      = "private_1a_subnet"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

# create private-1b subnet in us-east-1b:
resource "aws_subnet" "private_1b" {
  vpc_id                  = aws_vpc.handsone_vpc.id
  cidr_block              = "10.0.0.192/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name      = "private_1b_subnet"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

# create igw:
resource "aws_internet_gateway" "handsone_igw" {
  vpc_id = aws_vpc.handsone_vpc.id

  tags = {
    Name      = "handsone_igw"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

# create eip for natgw:
resource "aws_eip" "handsone_natgw_eip" {
  domain = "vpc"

  tags = {
    Name      = "handsone_natgw_eip"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

# create natgw:
resource "aws_nat_gateway" "handsone_natgw" {
  allocation_id = aws_eip.handsone_natgw_eip.id
  subnet_id     = aws_subnet.public_1a.id

  tags = {
    Name      = "handsone_natgw"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

# create public rtb:
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.handsone_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.handsone_igw.id
  }

  tags = {
    Name      = "handsone_public_rtb"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "public-rtb-to-public-1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "public-rtb-to-public-1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.public_rtb.id
}

# create private rtb:
resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.handsone_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.handsone_natgw.id
  }

  tags = {
    Name      = "handsone_private_rtb"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "private-rtb-to-private-1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_rtb.id
}

resource "aws_route_table_association" "private-rtb-to-private-1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private_rtb.id
}

# create public security group:
resource "aws_security_group" "public-sg" {
  name        = "public_sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.handsone_vpc.id

  ingress {
    description = "SSH from www"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from www"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "handsone_public_sg"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }
}

# lookup ami id of linux 2:
data "aws_ami" "amazon_linux_2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.*-x86_64-gp2"]
  }
}

output "asdf" {
  value = data.aws_ami.amazon_linux_2_ami.id
}

#create ec2 instance in public-1a:
resource "aws_instance" "public_1a_instance" {
  ami                    = data.aws_ami.amazon_linux_2_ami.id
  instance_type          = "t2.micro"
  key_name               = "tentek"
  vpc_security_group_ids = [aws_security_group.public-sg.id]
  subnet_id              = aws_subnet.public_1a.id
  user_data              = <<EOF
     #!/bin/bash
     yum update -y
     yum install httpd -y
     systemctl start httpd
     systemctl enable httpd
     echo "<h1>This is my public-1a instance</h1>" > /var/www/html/index.html
 EOF

  tags = {
    Name      = "public-1a-instance"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }

  depends_on = [aws_internet_gateway.handsone_igw]
}

# create ec2 instance in public-1b:
resource "aws_instance" "public_1b_instance" {
  ami                    = data.aws_ami.amazon_linux_2_ami.id
  instance_type          = "t2.micro"
  key_name               = "tentek"
  vpc_security_group_ids = [aws_security_group.public-sg.id]
  subnet_id              = aws_subnet.public_1b.id
  user_data              = <<EOF
    #!/bin/bash
    yum update -y
    yum install httpd -y
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>This is my public-1b instance</h1>" > /var/www/html/index.html
EOF

  tags = {
    Name      = "public-1b-instance"
    Team      = "DevOps"
    Env       = "test"
    ManagedBy = "Terraform"
  }

  depends_on = [aws_internet_gateway.handsone_igw]
}