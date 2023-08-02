provider aws {
  region = "us-east-1"

  allowed_account_ids = [
    "699899179833",
  ]
}

terraform {

  required_version = "= 1.0.11"

  backend "s3" {
    bucket         = "noname-derek-tf-state"
    key            = "aws/us-east-1/ecr.tfstate"
    region         = "us-east-1"
  }
}

output "repos" {
  value = local.app_repos
}

locals {
  app_repos = toset([
    "test-python",
  ])
}


resource "aws_ecr_repository" "apps" {
  for_each = local.app_repos
  name     = each.value

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
