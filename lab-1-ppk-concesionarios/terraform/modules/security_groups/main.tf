# Security group for the public-facing EC2 instance.
# SSH is restricted to a single configurable CIDR; HTTP is open to the world
# (there is no ALB/WAF in front of it, per the lab's constraints).
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "PPK web/dev server: SSH from admin IP only, HTTP open"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from the administrator/pentester IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP - serves both ppkconcesionario.com and dev.ppkconcesionario.com"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Unrestricted outbound (package installs, S3, RDS, git clone)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# Security group for RDS: only reachable from the EC2 instance, on the MySQL port.
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "PPK MySQL RDS: reachable only from the application EC2 instance"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from the application server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Unrestricted outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
