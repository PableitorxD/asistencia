terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # --- BACKEND REMOTO EN S3 + DYNAMODB ---
  backend "s3" {
    bucket         = "asistencia-tfstate-pablo-2026"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

# 1. Red Virtual (VPC)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "asistencia-vpc"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "asistencia-igw"
  }
}

# 3. Tabla de Rutas
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "asistencia-rt"
  }
}

# 4. Subred pública
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"

  tags = {
    Name = "asistencia-subnet"
  }
}

# 5. Asociación de tabla de rutas
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 6. Grupo de Seguridad (Permite SSH, HTTP 80 y Node.js 3000)
resource "aws_security_group" "app_sg" {
  name        = "asistencia-app-sg"
  description = "Permitir trafico HTTP, Node.js y SSH"
  vpc_id      = aws_vpc.main.id

  # Acceso SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Acceso Frontend Web (Puerto 80)
  ingress {
    description = "Frontend HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Acceso Backend Node.js (Puerto 3000)
  ingress {
    description = "Backend API Node.js"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida libre a Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "asistencia-app-sg"
  }
}

# 7. SERVIDOR 1: Backend (Node.js + SQLite)
resource "aws_instance" "backend_server" {
  ami                    = "ami-0fb653ca2d3203ac1" # Ubuntu 22.04 LTS
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "Asistencia-Backend-Server"
  }
}

# 8. SERVIDOR 2: Frontend (Vanilla JS / Nginx)
resource "aws_instance" "frontend_server" {
  ami                    = "ami-0fb653ca2d3203ac1" # Ubuntu 22.04 LTS
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "Asistencia-Frontend-Server"
  }
}

# Direcciones IP públicas resultantes
output "backend_public_ip" {
  description = "IP publica del Backend (Node.js)"
  value       = aws_instance.backend_server.public_ip
}

output "frontend_public_ip" {
  description = "IP publica del Frontend (Web)"
  value       = aws_instance.frontend_server.public_ip
}