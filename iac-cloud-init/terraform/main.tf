provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 1. Crear la VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "globomatics-vpc" }
}

# 2. Crear la Subred Pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { Name = "globomatics-subnet-public" }
}

# 3. Crear el Internet Gateway (Salida a Internet)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "globomatics-igw" }
}

# 4. Tabla de Ruteo
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "globomatics-rt" }
}

# Asociar la tabla de ruteo con la subred
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 5. Grupo de Seguridad
resource "aws_security_group" "app" {
  name        = "globomatics-app-sg"
  description = "Acceso web y SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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

# 6. Instancia EC2 con Cloud-Init
resource "aws_instance" "app" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../cloud-init.yaml", {
    package_json = filebase64("${path.module}/../app/package.json")
    server_js    = filebase64("${path.module}/../app/server.js")
    index_html   = filebase64("${path.module}/../app/public/index.html")
    init_sql     = filebase64("${path.module}/../app/db/init.sql")
    ambiente     = var.ambiente
    db_password  = var.db_password
  })

  user_data_replace_on_change = true

  tags = {
    Name = "servidor-terraform-cloudinit"
  }
}