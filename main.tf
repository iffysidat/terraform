provider "aws" {
    region = "eu-west-2"
}

data "aws_vpc" "myfirstvpc" {
    default = true
}

data "aws_subnet_ids" "myfirstsubnetids" {
    vpc_id = data.aws_vpc.myfirstvpc.id
}

resource "aws_instance" "myfirstinstance" {
    ami                    = "ami-0be057a22c63962cb"
    instance_type          = "t2.micro"
    vpc_security_group_ids = [aws_security_group.myfirstsecuritygroup.id]

    user_data = <<-EOF
              #!/bin/bash
              echo "Hello, my name is Irfan" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

    tags = {
        Name = "irfan-first-instance"
    }
}

resource "aws_security_group" "myfirstsecuritygroup" {
    name = "irfan-first-security-group"

    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "albsg" {
    name = "irfan-alb-securitygroup"

    # Allow inbound HTTP requests
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound requests
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_launch_configuration" "myfirstlaunchconfig" {
    image_id        = "ami-0be057a22c63962cb"
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.myfirstsecuritygroup.id]

    user_data = <<-EOF
              #!/bin/bash
              echo "Hello, my name is Irfan" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "myfirstasg" {
    launch_configuration    = aws_launch_configuration.myfirstlaunchconfig.name
    vpc_zone_identifier     = data.aws_subnet_ids.myfirstsubnetids.ids

    target_group_arns       = [aws_lb_target_group.myfirstasgtargetgroup.arn]
    health_check_type       = "ELB"

    min_size = 2
    max_size = 10

    tag {
        key                 = "Name"
        value               = "irfan-first-asg-example"
        propagate_at_launch = true
    }
}

resource "aws_lb" "myfirstlb" {
    name               = "irfan-first-loadbalancer"
    load_balancer_type = "application"
    subnets            = data.aws_subnet_ids.myfirstsubnetids.ids
    security_groups    = [aws_security_group.albsg.id]
}

resource "aws_lb_listener" "myfirstlistener" {
    load_balancer_arn = aws_lb.myfirstlb.arn
    port              = 80
    protocol          = "HTTP"

    # By default, return a simple 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code  = 404
        }
    }
}

resource "aws_lb_target_group" "myfirstasgtargetgroup" {
    name     = "irfan-first-asgtargetgroup"
    port     = var.server_port
    protocol = "HTTP"
    vpc_id   = data.aws_vpc.myfirstvpc.id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "myfirstlblistenerrule" {
    listener_arn = aws_lb_listener.myfirstlistener.arn
    priority     = 100

    condition {
        field  = "path-pattern"
        values = ["*"] 
    }

    action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.myfirstasgtargetgroup.arn 
    }
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type        = number
    default     = 8080
}

output "dns_alb_name" {
    value       = aws_lb.myfirstlb.dns_name
    description = "The domain name of the load balancer"
}