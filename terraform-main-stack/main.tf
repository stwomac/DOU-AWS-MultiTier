provider "aws" {
  region = "us-east-1"

  # set tag for every resource due to Account Policy
  default_tags {
    tags = {
      BatchID = "DevOps"
    }
  }
}

#create private key
resource "tls_private_key" "generic_rsa2048" {
  algorithm = "RSA"
}

# save private key locally
resource "local_file" "private-key-pem" {
  content  = tls_private_key.generic_rsa2048.private_key_pem
  filename = "womackRSA.pem"
}

# create a aws key pair from local private key
resource "aws_key_pair" "generic_rsa2048" {
  key_name   = "womackRSA"
  public_key = tls_private_key.generic_rsa2048.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}

# resource "random_id" "randomness" {
#   byte_length = 8
# }

# define vpc
resource "aws_vpc" "TerraformVPC" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# define private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.TerraformVPC.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value["az"] + 10) 
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value["az"]]

  tags = {
    Name = "private-${each.key}"
  }
}

# define public subnets
resource "aws_subnet" "public_subnets" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.TerraformVPC.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value["az"] + 100) 
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value["az"]]


}
# define internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.TerraformVPC.id
  tags = {
    Name = "womack-pj2"
  }
}

# set a ip for use in each nat gateway
resource "aws_eip" "nat_gateway_eip" {
  depends_on = [aws_internet_gateway.internet_gateway]
  for_each   = var.subnets
  tags = {
    Name = "womack-pj2-nat-gateway-eip-${each.key}"
  }

}

# define the nat gateways
resource "aws_nat_gateway" "nat_gateway" {
  for_each      = var.subnets
  depends_on    = [aws_subnet.public_subnets]
  allocation_id = aws_eip.nat_gateway_eip[each.key].id
  subnet_id     = aws_subnet.public_subnets[each.key].id # aws_subnet.public_subnets["public_subnet_1"].id
  tags = {
    Name = "womack-pj2-nat-${each.key}"
  }
}

# define the route table for public subnet to internet gateway
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.TerraformVPC.id

  route { #assigning route to internet by targeting ID of the IGW above
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

# define the route table for private subnets
resource "aws_route_table" "private_route_table" {

  for_each = var.subnets
  vpc_id   = aws_vpc.TerraformVPC.id

  route { #assigning route to internet by targeting ID of the nat gateway attached to each AZ
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[each.key].id
  }

}

# connect public subnets to public route table
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnets]
  route_table_id = aws_route_table.public_route_table.id
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}

# connect private subnets to private route table
resource "aws_route_table_association" "private" {
  for_each       = var.subnets
  subnet_id      = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_route_table[each.key].id
}

# defines load balancer security goup
resource "aws_security_group" "lb_sg" {
  name        = "LB SG - Womack"
  description = "Allow Inbound Traffic"
  vpc_id      = aws_vpc.TerraformVPC.id


  ingress {
    description = "Allow 443 from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["47.186.189.83/32"] # access is set to test machine, in production open as you wish
  }

  ingress {
    description = "Allow 80 from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["47.186.189.83/32"] # access is set to test machine, in production open as you wish
  }

  # ingress {
  #   description     = "Allow 80 from internet"
  #   from_port       = 3000
  #   to_port         = 3000
  #   protocol        = "tcp"
  #   cidr_blocks = ["47.186.189.83/32"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "womack-lb-sg"
  }
}

# defines security group for instances created through auto scaling on private subnet
resource "aws_security_group" "instance_sg" {
  depends_on  = [aws_security_group.lb_sg, aws_security_group.bastion_sg]
  name        = "EC2 SG - Womack"
  description = "Allow Inbound Traffic"
  vpc_id      = aws_vpc.TerraformVPC.id


  ingress {
    description     = "Allow 4200 from load balancer for front-end"
    from_port       = 4200
    to_port         = 4200
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    description     = "Allow 3000 from load balancer for back-end"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow access for ssh if you need to set up a bastion host for debugging
  ingress {
      description     = "Allow 22 from bastion"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      security_groups = [aws_security_group.bastion_sg.id]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "womack-web-server-sg"
  }
}

# defines security group for EFS mounts on private subnets
resource "aws_security_group" "mount_sg" {
  depends_on  = [aws_security_group.instance_sg]
  name        = "EFS SG - Womack"
  description = "Allow Inbound Traffic"
  vpc_id      = aws_vpc.TerraformVPC.id


  ingress {
    description     = "Allow 2049 for efs from ec2 instances"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.instance_sg.id]
  }

  # ingress {
  #   description     = "Allow 443 from internet"
  #   from_port       = 443
  #   to_port         = 443
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.instance_sg.id]
  # }

  # ingress {
  #   description     = "Allow 80 from internet"
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.instance_sg.id]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "womack-efs-mount-sg"
  }
}

# defines bastion host secuirty group for debugging
resource "aws_security_group" "bastion_sg" {
  name        = "Ec2 Bastion SG - Womack"
  description = "Allow Inbound Traffic"
  vpc_id      = aws_vpc.TerraformVPC.id


  ingress {
    description     = "Allow 22 from internet"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["47.186.189.83/32"] # access is set to test machine, in production open as you wish
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "womack-web_server"
  }
}

# defines application load balancer that will connect to private ec2 instances
resource "aws_lb" "load_balancer" {
  name               = "Terraform-Load-Balancer-Womack"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]

}

# defines load balancer target group to hit front-end container
resource "aws_lb_target_group" "tg_frontend" {
  name     = "target-group-frontend"
  port     = 4200
  protocol = "HTTP"
  vpc_id   = aws_vpc.TerraformVPC.id

  health_check {
    protocol = "HTTP"
    path     = "/"
  }

  tags = {
    Name = "target-group-frontend"
  }
}
# defines load balancer target group to hit back-end container
resource "aws_lb_target_group" "tg_backend" {
  name     = "target-group-backend"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.TerraformVPC.id

  health_check {
    protocol = "HTTP"
    path     = "/"
  }

  tags = {
    Name = "target-group-backend"
  }
}

# defines load balancer listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_frontend.arn
  }

  tags = {
    Name = "womack-listener"
  }
}

# defines load balancer listener rule, required since both containers are running on same instance
# backend api takes priority over frontend so we dont recieve frontend code
resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_backend.arn
  }
  
  # path pattern is the api routes
  condition {
    path_pattern {
      values = ["/dynamodb/*"]
    }
  }
}

# defines load balancer listener rule, required since both containers are running on same instance
# frontend api takes is lesser priority but has more permissive path pattern
resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_frontend.arn
  }
  
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# creates bastion host on AZ 1a
# Note that Key to the bastion host is also used as the key to the autoscale instances
resource "aws_instance" "web_server" {
  depends_on = [ aws_efs_mount_target.efs_mount ]
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnets["1a"].id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name = aws_key_pair.generic_rsa2048.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generic_rsa2048.private_key_pem
    host        = self.public_ip
  }

  # sets up object permissions for windows machine to access host
  provisioner "local-exec" {
    command = "powershell -Command \"(Get-Item '${local_file.private-key-pem.filename}').SetAccessControl((New-Object System.Security.AccessControl.FileSecurity -ArgumentList (Get-Item '${local_file.private-key-pem.filename}').FullName,'ContainerInherit,ObjectInherit'))\""
  }

  # copies over private key file from local machine for quick but less secure debugging
  provisioner "file" {
    source      = local_file.private-key-pem.filename  # The local path of womackRSA
    destination = "/home/ubuntu/womackRSA"            # The remote path on the server

    # You could alternatively place it in ~/.ssh/; just be mindful of permissions
  }

  tags = {
    Name = "womack-bastion"

  }

}

# creates the efs file system
resource "aws_efs_file_system" "efs" {
  creation_token = "womack-pj2"
  tags = {
    Name = "womack-pj2"
  }

}

# creates the efs mounts in each private subnet
resource "aws_efs_mount_target" "efs_mount" {
  depends_on = [ aws_security_group.mount_sg, aws_subnet.private_subnets ]
  for_each =  aws_subnet.private_subnets
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = aws_subnet.private_subnets[each.key].id
  security_groups = [aws_security_group.mount_sg.id]
}

# defines a IAM role to allow ec2 instances to access a specific DynamoDb
resource "aws_iam_role" "ec2_dynamodb_role" {
  name = "ec2_dynamodb_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# defines the policy for the IAM Role to allow access to a specific dynamodb table
resource "aws_iam_role_policy" "dynamodb_access_policy" {
  name   = "DynamoDBAccessPolicy"
  role   = aws_iam_role.ec2_dynamodb_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"
      }
    ]
  })
}

# Create IAM Instance Profile for autoscale use
resource "aws_iam_instance_profile" "ec2_dynamodb_instance_profile" {
  name = "womack_ec2_dynamodb_instance_profile"
  role = aws_iam_role.ec2_dynamodb_role.name
}

# defines the launch template for the autoscale group
resource "aws_launch_template" "ec2_template" {
  depends_on = [ aws_efs_mount_target.efs_mount, aws_efs_file_system.efs, aws_iam_instance_profile.ec2_dynamodb_instance_profile ]
  name_prefix            = "womack-pj2-"
  image_id               = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  instance_type          = "t3.small"
  user_data = base64encode(templatefile("user-data.sh", {var1 = aws_efs_file_system.efs.id})) # runs a shell script for installations and container running, efs id must be passed in because it can be dynamic
  key_name = aws_key_pair.generic_rsa2048.key_name # allows access from the bastion host
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_dynamodb_instance_profile.name
  }
  
  # sets the tags for the launch template
  tags = {
    BatchID = "DevOps"
  }

   # sets the tags on each ec2 instance
  tag_specifications {
    resource_type = "instance"

    tags = {
      BatchID = "DevOps"
      Name = "womack-autoscale"
    }
  }

}

# defines the autoscale group on the instances
resource "aws_autoscaling_group" "autoscale" {
  depends_on = [ aws_launch_template.ec2_template, aws_efs_mount_target.efs_mount, aws_efs_file_system.efs ]
  name                 = "womack-autoscale-group"
  desired_capacity     = 2
  min_size             = 1
  max_size             = 4
  health_check_type    = "ELB"
  health_check_grace_period = 600
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier  = values(aws_subnet.private_subnets)[*].id

  launch_template {
    id      = aws_launch_template.ec2_template.id
  }
  
  tag {
    key = "BatchID"
    value = "DevOps"
    propagate_at_launch = true
  }
  
}

# attaches the load balancer frontend target group to autoscaling instances
resource "aws_autoscaling_attachment" "frontend_aa" {
  depends_on = [ aws_lb.load_balancer, aws_autoscaling_group.autoscale ]
  autoscaling_group_name = aws_autoscaling_group.autoscale.id
  lb_target_group_arn = aws_lb_target_group.tg_frontend.arn
}

# attaches the load balancer frontend target group to autoscaling instances
resource "aws_autoscaling_attachment" "backend_aa" {
  depends_on = [ aws_lb.load_balancer, aws_autoscaling_group.autoscale ]
  autoscaling_group_name = aws_autoscaling_group.autoscale.id
  lb_target_group_arn = aws_lb_target_group.tg_backend.arn
}
