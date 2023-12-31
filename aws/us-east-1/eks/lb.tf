resource "aws_lb" "lb" {
  name               = "derek-test"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = local.private_subnets

  enable_deletion_protection = true

  tags = {
    Environment = "test"
    Candidate   = "Derek"
    Terraform   = "true"
  }
}

resource "aws_lb_target_group" "python-test" {
  name     = "python-test"
  port     = 30005
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  target_type = "instance"

  health_check {
    path = "/test1"
    enabled = true
  }

  tags = {
    Environment = "test"
    Candidate   = "Derek"
    Terraform   = "true"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.python-test.arn
  }
}

resource "aws_autoscaling_traffic_source_attachment" "eks" {
  for_each = toset(module.eks.eks_managed_node_groups_autoscaling_group_names)
  autoscaling_group_name = each.value

  traffic_source {
    identifier = aws_lb_target_group.python-test.arn
    type       = "elbv2"
  }
}

resource "aws_security_group" "lb" {
  name        = "derek-lb-test"
  description = "Allow inbound traffic"
  vpc_id      = local.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Environment = "test"
    Candidate   = "Derek"
    Terraform   = "true"
  }
}

// Z0193262SXR5F7V3J0MD
resource "aws_route53_record" "dns" {
  zone_id = "Z0193262SXR5F7V3J0MD"
  name    = "derek.nonamesec.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.lb.dns_name]
}
