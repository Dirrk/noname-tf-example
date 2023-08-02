provider aws {
  region = "us-east-1"

  allowed_account_ids = [
    "699899179833",
  ]
}

terraform {

  required_version = "= 1.0.11"

  # backend "s3" {
  #   bucket         = "noname-derek-tf-state"
  #   key            = "init.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "tf-locking-table"
  # }
}

resource "aws_s3_bucket" "terraform" {
  name = "noname-derek-tf-state"
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
resource "aws_s3_bucket_acl" "terraform" {
  bucket = aws_s3_bucket.terraform.bucket
  acl    = "private"
}

resource "aws_dynamodb_table" "terraform-locking-table" {
  name           = "tf-locking-table"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = "test"
    Candidate   = "Derek"
    Terraform   = "true"
  }
}
