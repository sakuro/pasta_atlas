# Bastion for DB inspection via SSM Session Manager.
# To create: terraform apply -var="create_bastion=true"
# To destroy: terraform apply

# Always-present: IAM and network infrastructure

resource "aws_iam_role" "bastion" {
  name = "${var.app_name}-${var.environment}-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "bastion_secrets" {
  name = "${var.app_name}-${var.environment}-bastion-secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_db_instance.main.master_user_secret[0].secret_arn
      },
      {
        Effect   = "Allow"
        Action   = "rds:DescribeDBInstances"
        Resource = aws_db_instance.main.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_secrets" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion_secrets.arn
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.app_name}-${var.environment}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_security_group" "bastion" {
  name        = "${var.app_name}-${var.environment}-bastion"
  description = "Bastion for DB inspection via SSM"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

output "rds_secret_arn" {
  value     = aws_db_instance.main.master_user_secret[0].secret_arn
  sensitive = true
}

output "rds_host" {
  value     = aws_db_instance.main.address
  sensitive = true
}

# Conditional: present only when create_bastion = true

data "aws_ami" "amazon_linux_2023" {
  count       = var.create_bastion ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_bastion" {
  count                        = var.create_bastion ? 1 : 0
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.bastion.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_instance" "bastion" {
  count                       = var.create_bastion ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2023[0].id
  instance_type               = "t3.nano"
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.app_name}-${var.environment}-bastion"
  }
}

resource "aws_iam_user_policy" "sakuro_ssm_bastion" {
  count = var.create_bastion ? 1 : 0
  name  = "${var.app_name}-${var.environment}-ssm-bastion"
  user  = "sakuro"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:StartSession",
        "ssm:TerminateSession",
        "ssm:ResumeSession",
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus"
      ]
      Resource = [
        aws_instance.bastion[0].arn,
        "arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"
      ]
    }]
  })
}

output "bastion_instance_id" {
  value = var.create_bastion ? aws_instance.bastion[0].id : null
}
