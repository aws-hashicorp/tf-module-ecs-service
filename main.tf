# ECR Repository
resource "aws_ecr_repository" "ecr" {
  name                 = var.service_name
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    tags = var.tags
  }
}

# ALB Target Group
resource "aws_alb_target_group" "target_group" {
  name             = "tg-${var.target_group_name}"
  port             = var.target_group_port
  protocol         = var.target_group_protocol
  vpc_id           = var.vpc_id
  target_type      = "ip"
  protocol_version = var.target_group_protocol_version

  health_check {
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    protocol            = var.health_check_protocol
    matcher             = var.health_check_port
    path                = var.health_check_path
  }

  tags = {
    tags = var.tags
  }
}

# ALB Listener
resource "aws_alb_listener" "listener_service" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  certificate_arn   = var.listener_protocol == "HTTPS" ? var.certificate_arn : ""

  default_action {
    target_group_arn = aws_alb_target_group.target_group.id
    type             = "forward"
  }

  tags = {
    tags = var.tags
  }

}

# ECS Task Definition
resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.service_name
  requires_compatibilities = var.requires_compatibilities
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.ram
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions    = jsonencode(var.container_definitions)

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = {
    tags = var.tags
  }
}

# ECS Service
resource "aws_ecs_service" "ecs_services" {
  name                              = var.service_name
  cluster                           = var.cluster_name
  task_definition                   = aws_ecs_task_definition.task_definition.arn
  desired_count                     = var.desired_task
  enable_execute_command            = true
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = var.grace_period

  network_configuration {
    security_groups  = [var.security_group_id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.target_group.arn
    container_name   = var.service_name
    container_port   = var.service_port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    tags = var.tags
  }
}

# ECS Auto Scaling
resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = format("service/%s/%s", var.cluster_name, var.service_name)
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

resource "aws_appautoscaling_policy" "up" {
  name               = "${var.service_name}_scale_up"
  service_namespace  = "ecs"
  resource_id        = format("service/%s/%s", var.cluster_name, var.service_name)
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_appautoscaling_policy" "down" {
  name               = "${var.service_name}_scale_down"
  service_namespace  = "ecs"
  resource_id        = format("service/%s/%s", var.cluster_name, var.service_name)
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "cloud_watch_logs" {
  name              = "/ecs-${var.service_name}"
  retention_in_days = var.log_group_retention

  tags = {
    tags = var.tags
  }
}

# ScalingUp CPU
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.service_name}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.up.arn]
}

# ScalingDown CPU
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "${var.service_name}_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.cpu_low_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [aws_appautoscaling_policy.down.arn]
}
