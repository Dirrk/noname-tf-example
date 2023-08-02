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
    key            = "aws/us-east-1/eks.tfstate"
    region         = "us-east-1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.4"

  cluster_name    = "derek-test"
  cluster_version = "1.27"

  cluster_endpoint_public_access  = true

  vpc_id                   = "vpc-09cf75f05de5b433e"
  subnet_ids               = ["subnet-04102795c60e02f9d", "subnet-09ac094aa2ae3df0b"]
  control_plane_subnet_ids = ["subnet-07c25242abaef4f31", "subnet-083a7542e97344698"]

  eks_managed_node_groups = {
    blue = {}
    green = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::699899179833:role/CandidateTestRole"
      username = "CandidateTestRole"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::699899179833:user/Derek"
      username = "Derek"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [
    "699899179833",
  ]

  tags = {
    Environment = "test"
    Candidate   = "Derek"
    Terraform   = "true"
  }
}
