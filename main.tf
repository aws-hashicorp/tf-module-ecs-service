# Security Group
resource "aws_security_group" "sg_ecs_service" {
  name   = "${var.service_name}-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_cidrs != null && length(var.allowed_cidrs) > 0 ? [1] : []
    content {
      from_port   = var.sg_listener_port_from
      to_port     = var.sg_listener_port_to
      protocol    = var.sg_listener_protocol
      cidr_blocks = var.allowed_cidrs
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_security_groups != null && length(var.allowed_security_groups) > 0 ? [1] : []
    content {
      from_port       = var.sg_listener_port_from
      to_port         = var.sg_listener_port_to
      protocol        = var.sg_listener_protocol
      security_groups = var.allowed_security_groups
      description     = "Allow from security groups"
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_prefix_list_ids != null && length(var.allowed_prefix_list_ids) > 0 ? [1] : []
    content {
      from_port       = var.sg_listener_port_from
      to_port         = var.sg_listener_port_to
      protocol        = var.sg_listener_protocol
      prefix_list_ids = var.allowed_prefix_list_ids
      description     = "Allow from prefix lists"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.service_name}-sg" })
}

# IAM Role
resource "aws_iam_role" "iam_task_role" {
  name               = "taskAndExecuteRole-${var.service_name}"
  assume_role_policy = file("${path.module}/policies/ecs-trusted_policy.json")

  tags = var.tags
}

# Attach Policies
resource "aws_iam_role_policy_attachment" "role_policy_attach" {
  role       = aws_iam_role.iam_task_role.name
  count      = length(var.permissions_name)
  policy_arn = element(data.aws_iam_policy.role_permissions_data.*.id, count.index)
}

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

  tags = var.tags
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

  tags = var.tags
}

# ALB Listener
resource "aws_alb_listener" "listener_service" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    target_group_arn = aws_alb_target_group.target_group.id
    type             = "forward"
  }

  tags = var.tags
}

# Listener Rule
resource "aws_lb_listener_rule" "listener_rule_set" {
  count        = var.create_listener_rule ? 1 : 0
  listener_arn = var.target_group_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.target_group.arn
  }

  condition {
    path_pattern {
      values = var.listener_rule_path_patterns
    }
  }

  tags = {
    Name = "${var.service_name}"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.service_name
  requires_compatibilities = var.requires_compatibilities
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.ram
  execution_role_arn       = aws_iam_role.iam_task_role.arn
  task_role_arn            = aws_iam_role.iam_task_role.arn
  container_definitions    = var.container_definitions

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "ecs_services" {
  name                              = var.service_name
  cluster                           = var.cluster_name
  task_definition                   = aws_ecs_task_definition.task_definition.arn
  desired_count                     = var.desired_task
  enable_execute_command            = true
  health_check_grace_period_seconds = var.grace_period

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  network_configuration {
    security_groups  = [aws_security_group.sg_ecs_service.id]
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

  tags = var.tags
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
  name              = "/ecs/${var.service_name}"
  retention_in_days = var.log_group_retention

  tags = var.tags
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
