resource "aws_ecs_cluster" "app" {
  name = "${var.project_env}-ecs-cluster"
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_env}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_env}-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  
container_definitions = jsonencode([
  {
    name      = "app"
    image     = var.ecr_image_url
    essential = true
    command   = ["sh", "-c", "php artisan migrate --force && php artisan storage:link --force && apache2-foreground"]

    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]

    environment = [
      { name = "APP_ENV",       value = "local" },
      { name = "APP_DEBUG",     value = "true" },
      { name = "LOG_CHANNEL",   value = "stderr" },
      { name = "APP_URL",       value = var.app_url },
      { name = "ASSET_URL",     value = var.app_url },
      { name = "DB_CONNECTION", value = "mysql" },
      { name = "DB_HOST",       value = var.db_host },
      { name = "DB_PORT",       value = "3306" },
      { name = "DB_DATABASE",   value = var.db_name },
      { name = "DB_USERNAME",   value = var.db_username },
    ]

    secrets = [
      { name = "APP_KEY",     valueFrom = var.app_key_secret_arn },
      { name = "DB_PASSWORD", valueFrom = var.db_password_secret_arn },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_env}"
        "awslogs-region"        = "ap-northeast-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }
])


  
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_env}"
  retention_in_days = 7
}

resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = "${var.project_env}-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [
        var.app_key_secret_arn,
        var.db_password_secret_arn
      ]
    }]
  })
}



#セキュリティグループ
resource "aws_security_group" "alb_sg" {
    vpc_id = var.vpc_id
    name = "alb_sg"

    tags = {
        Name = "${var.project_env}-alb-sg"}
    }
  
resource "aws_vpc_security_group_ingress_rule" "web_http" {
    security_group_id = aws_security_group.alb_sg.id

    cidr_ipv4 = "0.0.0.0/0"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80

}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
    security_group_id = aws_security_group.alb_sg.id

    cidr_ipv4 = "0.0.0.0/0"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
 
}
resource "aws_vpc_security_group_egress_rule" "web_egress_all" {
  security_group_id = aws_security_group.alb_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}



resource "aws_lb" "app" {
  name               = "${var.project_env}-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    var.public_subnet1a,
    var.public_subnet1c
  ]

  tags = {
    Name = "${var.project_env}-alb"
  }
}


resource "aws_lb_target_group" "app" {
  name        = "${var.project_env}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path = "/"
    port = "80"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_env}-app-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets         = [var.ecs_subnet1a, var.ecs_subnet1c]  # ← 複数AZ
    security_groups = [aws_security_group.dev_ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http
  ]
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_env}-ecs-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

#セキュリティグループ
resource "aws_security_group" "dev_ecs_sg" {
    vpc_id = var.vpc_id
    name = "dev_ecs_sg"

    tags = {
        Name = "${var.project_env}-ecs-sg"}
    }
  
resource "aws_vpc_security_group_ingress_rule" "alb-route" {
    security_group_id = aws_security_group.dev_ecs_sg.id
    referenced_security_group_id = aws_security_group.alb_sg.id
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80

}

resource "aws_vpc_security_group_egress_rule" "ecs_egress_all" {
  security_group_id = aws_security_group.dev_ecs_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}