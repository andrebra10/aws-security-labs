# Random secret key used to sign the FastAPI session cookie. Not part of the
# vulnerability chain, just required for the app to run.
resource "random_id" "app_secret_key" {
  byte_length = 32
}

module "network" {
  source = "../../modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security_groups" {
  source = "../../modules/security_groups"

  project_name     = var.project_name
  vpc_id           = module.network.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "s3" {
  source = "../../modules/s3"

  bucket_name_prefix = var.bucket_name_prefix
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  bucket_arn   = module.s3.bucket_arn
}

module "rds" {
  source = "../../modules/rds"

  project_name          = var.project_name
  private_subnet_ids    = module.network.private_subnet_ids
  rds_security_group_id = module.security_groups.rds_sg_id
  db_name               = var.db_name
  db_username           = var.db_username
  instance_class        = var.db_instance_class
}

module "ec2" {
  source = "../../modules/ec2"

  project_name          = var.project_name
  subnet_id             = module.network.public_subnet_ids[0]
  security_group_id     = module.security_groups.ec2_sg_id
  instance_profile_name = module.iam.instance_profile_name
  instance_type         = var.instance_type
  github_repo_url       = var.github_repo_url
  dev_password          = var.dev_password
  app_secret_key        = random_id.app_secret_key.hex
  aws_region            = var.aws_region
  bucket_name           = module.s3.bucket_name

  db_host     = module.rds.db_host
  db_port     = module.rds.db_port
  db_name     = module.rds.db_name
  db_username = module.rds.db_username
  db_password = module.rds.db_password
}
