##############################################################################
# aws-devops-lab — Terraform root
# Composes: networking · ecr · ecs · alb · iam
##############################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key            = "aws-devops-lab/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "aws-devops-lab"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "diegonunfio"
      Repository  = "https://github.com/diegonunfio/aws-devops-lab"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "networking" {
  source = "./modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "ecr" {
  source = "./modules/ecr"

  repository_name      = "aws-devops-lab-api"
  environment          = var.environment
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
}

module "ecs" {
  source = "./modules/ecs"

  environment           = var.environment
  aws_region            = var.aws_region
  cluster_name          = "aws-devops-lab-${var.environment}"
  service_name          = "aws-devops-lab-service"
  container_name        = "api"
  container_image       = "${module.ecr.repository_url}:latest"
  container_port        = 3000
  desired_count         = var.ecs_desired_count
  cpu                   = var.ecs_cpu
  memory                = var.ecs_memory

  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_target_group_arn  = module.alb.target_group_arn
  ecs_security_group_id = module.networking.ecs_sg_id

  depends_on = [module.alb]
}

module "alb" {
  source = "./modules/alb"

  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_sg_id
  container_port        = 3000
  certificate_arn       = var.acm_certificate_arn
}

module "iam" {
  source = "./modules/iam"

  environment  = var.environment
  ecr_repo_arn = module.ecr.repository_arn
}
