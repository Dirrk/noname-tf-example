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
    key            = "init.tfstate"
    region         = "us-east-1"
  }
}

resource "aws_s3_bucket" "terraform" {
  bucket = "noname-derek-tf-state"
  tags = {
    Environment = "test"
    Candidate   = "Derek"
    Terraform   = "true"
  }
}
resource "aws_s3_bucket_public_access_block" "terraform" {
  bucket = aws_s3_bucket.terraform.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform" {
  bucket = aws_s3_bucket.terraform.bucket

  versioning_configuration {
    status = "Enabled"
  }
}
