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

locals {
  vpc_id = "vpc-09cf75f05de5b433e"
  private_subnets = ["subnet-04102795c60e02f9d", "subnet-09ac094aa2ae3df0b"]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.4"

  cluster_name    = "derek-test"
  cluster_version = "1.27"

  cluster_endpoint_public_access  = false

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnets
  control_plane_subnet_ids = local.private_subnets

  iam_role_arn = "arn:aws:iam::699899179833:role/eksClusterRole"

  eks_managed_node_groups = {
    green = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      create_iam_role = false
      iam_role_arn = "arn:aws:iam::699899179833:role/EksNodeGroupInstanceRole"

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
    }
  }

  manage_aws_auth_configmap = false
  create_cloudwatch_log_group = false
  create_iam_role = false
  create_kms_key = false
  cluster_encryption_config = {}
  enable_irsa = false

  cluster_security_group_additional_rules = {
    open = {
      protocol = "TCP"
      from_port = "443"
      to_port = "443"
      type = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  node_security_group_additional_rules = {
    test-python = {
      protocol = "TCP"
      from_port = "30005"
      to_port = "30005"
      type = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

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
