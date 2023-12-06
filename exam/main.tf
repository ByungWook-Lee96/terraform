# terraform 버전 설정
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.5.0"
    }
  }

  required_version = ">= 0.14.9"
}

# 공급자 설정
provider "aws" {
  profile = "default"
  region  = "ap-northeast-2"
}


# VPC 및 보안그룹 설정
# groomVPC 설정
resource "aws_vpc" "groomVPC" {
  cidr_block = "10.0.0.0/24"
  
  tags = {
    Name = "groomVPC"
  }
}

# Pubilc Web a 의 서브넷 구성
resource "aws_subnet" "Public_Web_a" {
  vpc_id                  = aws_vpc.groomVPC.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "Public_Web_a"
  }
}

# Public Web c 의 서브넷 구성
resource "aws_subnet" "Public_Web_c" {
  vpc_id                  = aws_vpc.groomVPC.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-2c"

  tags = {
    Name = "Public_Web_c"
  }
}

# Private App a 의 서브넷 구성
resource "aws_subnet" "Private_App_a" {
  vpc_id                  = aws_vpc.groomVPC.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "Private_App_a"
  }
}

# Private App c 의 서브넷 구성
resource "aws_subnet" "Private_App_c" {
  vpc_id                  = aws_vpc.groomVPC.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "ap-northeast-2c"

  tags = {
    Name = "Private_App_c"
  }
}

# Private DB a 의 서브넷 구성
resource "aws_subnet" "Private_DB_a" {
  vpc_id                  = aws_vpc.groomVPC.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "ap-northeast-2a"

  tags = {
    Name = "Private_DB_a"
  }
}

# Private DB c 의 서브넷 구성
resource "aws_subnet" "Private_DB_c" {
  vpc_id                  = aws_vpc.groomVPC.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = "ap-northeast-2c"

  tags = {
    Name = "Private_DB_c"
  }
}

# web 보안 그룹 설정
resource "aws_security_group" "presentation_tier" {
  name        = "allow_connection_to_presentation_tier"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.groomVPC.id

  ingress {
    description     = "HTTP from anywhere"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_presentation_tier.id]
  }

  ingress {
    description     = "HTTP from anywhere"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_presentation_tier.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "presentation_tier_sg"
  }
}

resource "aws_security_group" "alb_presentation_tier" {
  name        = "allow_connection_to_alb_presentation_tier"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.groomVPC.id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_presentation_tier_sg"
  }
}

# app 보안 그룹 설정
resource "aws_security_group" "application_tier" {
  name        = "allow_connection_to_application_tier"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.groomVPC.id
  ingress {
    description     = "HTTP from public subnet"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_application_tier.id]
  }

  ingress {
    description     = "HTTP from public subnet"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_application_tier.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "application_tier_sg"
  }
}

resource "aws_security_group" "alb_application_tier" {
  name        = "allow_connection_to_alb_application_tier"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.groomVPC.id

  ingress {
    description     = "HTTP from anywhere"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.presentation_tier.id]
  }

  ingress {
    description     = "HTTP from anywhere"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.presentation_tier.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_application_tier_sg"
  }
}

# gateway 설정
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.groomVPC.id

  tags = {
    Name = "gw"
  }
}

# Web Route Table 설정
resource "aws_route_table" "Web_Route_Table" {
  vpc_id = aws_vpc.groomVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Web_Route_Table"
  }
}

# Web_Route_Table에 연결 1
resource "aws_route_table_association" "public_route_association1" {
  subnet_id      = aws_subnet.Public_Web_a.id
  route_table_id = aws_route_table.Web_Route_Table.id
}

# Web_Route_Table에 연결 2
resource "aws_route_table_association" "public_route_association2" {
  subnet_id      = aws_subnet.Public_Web_c.id
  route_table_id = aws_route_table.Web_Route_Table.id
}

# App Route Table 설정
resource "aws_route_table" "App_Route_Table" {
  vpc_id = aws_vpc.groomVPC.id

  tags = {
    Name = "private_route"
  }
}
resource "aws_route" "private_nat" {
  count                       = length(var.private_subnet_ids)
  route_table_id              = aws_route_table.App_Route_Table.id
  destination_cidr_block      = "0.0.0.0/0"
  nat_gateway_id              = aws_nat_gateway.nat_gateway[count.index].id
  depends_on = [aws_nat_gateway.nat_gateway]
}

# App_Route_Table에 연결 1
resource "aws_route_table_association" "private-route1" {
  subnet_id      = aws_subnet.Private_App_a.id
  route_table_id = aws_route_table.App_Route_Table.id
}

# App_Route_Table에 연결 2
resource "aws_route_table_association" "private-route2" {
  subnet_id      = aws_subnet.Private_App_c.id
  route_table_id = aws_route_table.App_Route_Table.id
}

# subnet 변수 사용
variable "public_subnet_ids" {
  type    = list(string)
  default = ["Public_Web_a", "Public_Web_c"]
}

# subnet 변수 사용
variable "private_subnet_ids" {
  type    = list(string)
  default = ["Private_App_a", "Private_App_c"]
}

# App의 인터넷 통신을 위한 nat gateway 생성
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(var.public_subnet_ids)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.Public_Web_a.id

  tags = {
    "Name" = "nat_gateway"
  }
}

# nat을 사용하기 위해서 eip 사용
resource "aws_eip" "nat" {
  count = length(var.public_subnet_ids)
  vpc   = true

  lifecycle {
    create_before_destroy = true
  }
}


# Web_lb 설정
resource "aws_lb" "Web_lb" {
  count              = length(var.public_subnet_ids)
  name               = "Web-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_presentation_tier.id]
  subnets            = [var.public_subnet_ids[count.index]]
}

resource "aws_lb_listener" "Web_lb" {
  count             = length(aws_lb.Web_lb)
  load_balancer_arn = aws_lb.Web_lb[count.index].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Web_lb[count.index].arn
  }
}

resource "aws_lb_target_group" "Web_lb" {
  count = length(var.public_subnet_ids)

  name     = "web-lb-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.groomVPC.id
}


# App_lb 설정
resource "aws_lb" "App_lb" {
  count              = length(var.private_subnet_ids)
  name               = "App-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_application_tier.id]
  subnets            = [var.private_subnet_ids[count.index]]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "App_lb" {
  count             = length(aws_lb.App_lb)
  load_balancer_arn = aws_lb.App_lb[count.index].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.App_lb[count.index].arn
  }
}

resource "aws_lb_target_group" "App_lb" {
  count = length(var.private_subnet_ids)

  name     = "App-lb-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.groomVPC.id
}

# Auto Scaling group 설정 - Web
resource "aws_autoscaling_group" "presentation_tier" {
  count                     = length(var.public_subnet_ids)
  name                      = "Web-ASG-Pres-Tier"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.Public_Web_a.id, aws_subnet.Public_Web_c.id]

  launch_template {
        id      = aws_launch_template.presentation_tier[count.index].id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tag {
    key                 = "Name"
    value               = "presentation_app"
    propagate_at_launch = true
  }
}

# Auto Scaling group 설정 - App
resource "aws_autoscaling_group" "application_tier" {
  count                     = length(var.private_subnet_ids)
  name                      = "App-ASG-App-Tier"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.Private_App_a.id, aws_subnet.Private_App_c.id]

  launch_template {
    id      = aws_launch_template.application_tier[count.index].id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tag {
    key                 = "Name"
    value               = "application_app"
    propagate_at_launch = true
  }
}



# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "presentation_tier" {
  count                  = length(var.public_subnet_ids)
  autoscaling_group_name = aws_autoscaling_group.presentation_tier[count.index].id
  lb_target_group_arn    = aws_lb_target_group.Web_lb[count.index].arn
}

resource "aws_autoscaling_attachment" "application_tier" {
  count                  = length(var.private_subnet_ids)
  autoscaling_group_name = aws_autoscaling_group.application_tier[count.index].id
  lb_target_group_arn    = aws_lb_target_group.App_lb[count.index].arn
}



# EC2 생성
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_instance_profile" "ec2_ecr_connection" {
  name = "ec2_ecr_connection"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "allow_ec2_access_ecr"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "access_ecr_policy" {
  name = "allow_ec2_access_ecr"
  role = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_launch_template" "presentation_tier" {
  count = length(var.public_subnet_ids)
  name  = "presentation_tier"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 8
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ecr_connection.name
  }

  instance_type = "t2.micro"
  image_id      = data.aws_ami.amazon_linux_2.id

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.presentation_tier.id]
  }
  user_data = <<-EOF
              #!/bin/bash
              echo "ALB DNS Name: ${aws_lb.Web_lb[count.index].dns_name}" >> /tmp/alb_info.txt
              EOF

  depends_on = [
    aws_lb.Web_lb
  ]
}

resource "aws_launch_template" "application_tier" {
  count = length(var.private_subnet_ids)

  name = "application_tier"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ecr_connection.name
  }

  instance_type = "t2.micro"
  image_id      = data.aws_ami.amazon_linux_2.id

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.application_tier.id]
  }

  depends_on = [
    aws_lb.Web_lb
  ]
}

# RDS 사용
resource "aws_db_subnet_group" "db-subnet-group" {
  count      = length(var.private_subnet_ids)
  name       = "db_subnet_group"
  subnet_ids = [var.private_subnet_ids[count.index]]

  tags = {
    Name = "db_subnet_group"
  }
}

resource "aws_security_group" "rds-sg" {
  name        = "RDSSG"
  description = "Allows application tier to access the RDS instance"
  vpc_id      = aws_vpc.groomVPC.id

  ingress {
    description     = "EC2 to MYSQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application_tier.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_sg"
  }
}


resource "aws_db_instance" "rds" {
  count                  = length(var.private_subnet_ids)
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-group[count.index].name
  allocated_storage      = 1
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "instance_class"
  multi_az               = false
  db_name                = "db_name"
  username               = "rds_db_admin"
  password               = "rds_db_password"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.application_tier.id]
}

output "rds_address" {
  value = [for rds in aws_db_instance.rds : rds.address]
}

// IAM 설정
resource "aws_iam_user" "example" {
  name = "aws_learner_cd_user"
}

resource "aws_iam_user_policy" "example" {
  name   = "example_policy"
  user   = aws_iam_user.example.name

  // 권한 추가
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "rds:Describe*",
        "elasticloadbalancing:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

