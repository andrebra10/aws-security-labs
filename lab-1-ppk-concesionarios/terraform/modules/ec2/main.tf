data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Admin/pentester keypair - used only to manage the box, unrelated to the
# vulnerability chain (that runs entirely through password SSH as 'pepe').
resource "tls_private_key" "admin" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "admin" {
  key_name   = "${var.project_name}-admin-key"
  public_key = tls_private_key.admin.public_key_openssh
}

resource "local_file" "admin_private_key" {
  filename        = "${path.root}/generated/${var.project_name}-admin-key.pem"
  content         = tls_private_key.admin.private_key_pem
  file_permission = "0600"
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = var.instance_profile_name
  key_name               = aws_key_pair.admin.key_name

  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    github_repo_url = var.github_repo_url
    dev_password    = var.dev_password
    app_secret_key  = var.app_secret_key
    db_host         = var.db_host
    db_port         = var.db_port
    db_name         = var.db_name
    db_username     = var.db_username
    db_password     = var.db_password
    bucket_name     = var.bucket_name
    aws_region      = var.aws_region
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-web-server"
  }
}
