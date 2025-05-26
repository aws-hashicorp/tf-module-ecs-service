variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}

# Target Group Variables
variable "target_group_name" {
  description = "The name of the target group"
  type        = string
}

variable "target_group_port" {
  description = "The port of the target group"
  type        = number
}

variable "target_group_protocol" {
  description = "The protocol of the target group"
  type        = string
}

variable "target_group_protocol_version" {
  description = "The protocol version of the target group"
  type        = string
}

variable "health_check_timeout" {
  description = "The timeout for the health check"
  type        = number
}

variable "health_check_unhealthy_threshold" {
  description = "The unhealthy threshold for the health check"
  type        = number
}

variable "health_check_healthy_threshold" {
  description = "The healthy threshold for the health check"
  type        = number
}

variable "health_check_interval" {
  description = "The interval for the health check"
  type        = number
}

variable "health_check_protocol" {
  description = "The protocol for the health check"
  type        = string
}

variable "health_check_port" {
  description = "The port for the health check"
  type        = number
}

variable "health_check_path" {
  description = "The path for the health check"
  type        = string
}

# Load Balancer Variables
variable "load_balancer_arn" {
  description = "The ARN of the load balancer"
  type        = string
}

variable "listener_port" {
  description = "The port for the listener"
  type        = number
}

variable "listener_protocol" {
  description = "The protocol for the listener"
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the certificate"
  type        = string
}


# Task Definition Variables
variable "cpu" {
  description = "The number of CPU units to allocate to the task"
  type        = number
}

variable "ram" {
  description = "The amount of memory (in MiB) to allocate to the task"
  type        = number
}

variable "execution_role_arn" {
  description = "The execution role ARN for the ECS task"
  type        = string
}

variable "task_role_arn" {
  description = "The task role ARN for the ECS task"
  type        = string
}

variable "requires_compatibilities" {
  description = "The launch type required for the task"
  type        = list(string)
}

variable "container_definitions" {
  description = "The container definitions for the ECS task"
  type = list(object({
    name      = string
    image     = string
    essential = bool
    portMappings = list(object({
      containerPort = number
      hostPort      = number
      protocol      = string
    }))
    logConfiguration = object({
      logDriver = string
      options   = map(string)
    })
  }))
}

# Service Variables
variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "service_port" {
  description = "The port for the ECS service"
  type        = number
}

variable "cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "desired_task" {
  description = "The desired number of tasks"
  type        = number
}

variable "grace_period" {
  description = "The grace period for the service"
  type        = number
}

variable "security_group_id" {
  description = "The ID of the security group"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

# Auto Scaling Variables
variable "min_capacity" {
  description = "The minimum capacity for the auto scaling group"
  type        = number
}

variable "max_capacity" {
  description = "The maximum capacity for the auto scaling group"
  type        = number
}

# CloudWatch Logs Variables
variable "log_group_retention" {
  description = "The retention period (in days) for the CloudWatch log group"
  type        = number
}

# CloudWatch Alarms Variables
variable "evaluation_periods" {
  description = "The number of periods over which data is evaluated"
  type        = number
}

variable "cpu_high_threshold" {
  description = "The CPU utilization threshold for scaling up"
  type        = number
}

variable "cpu_low_threshold" {
  description = "The CPU utilization threshold for scaling down"
  type        = number
}
