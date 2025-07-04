# --- Global Variables ---
variable "service_name" {
  description = "The name of the ECS service"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

# --- Security Group Variables ---
variable "allowed_cidrs" {
  description = "The CIDR blocks to allow"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "The security groups to allow"
  type        = list(string)
  default     = []
}

variable "allowed_prefix_list_ids" {
  description = "The prefix list IDs to allow"
  type        = list(string)
  default     = []
}

variable "sg_listener_port_from" {
  description = "The starting port for the security group listener"
  type        = number
  default     = 80
}

variable "sg_listener_port_to" {
  description = "The ending port for the security group listener"
  type        = number
  default     = 80
}

variable "sg_listener_protocol" {
  description = "The protocol for the security group listener"
  type        = string
  default     = "tcp"
}

# --- IAM Role Variables ---
variable "permissions_name" {
  description = "List name of policies for role"
  type        = list(string)
  default     = []
}

# --- Target Group Variables ---
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

# --- Load Balancer Variables ---
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

# --- Listener Rule Variables ---
variable "create_listener_rule" {
  description = "Whether to create a listener rule"
  type        = bool
  default     = true
}

variable "target_group_arn" {
  description = "The ARN of the target group"
  type        = string
  default     = ""
}

variable "listener_rule_priority" {
  description = "The priority for the listener rule"
  type        = number
  default     = 1
}

variable "listener_rule_path_patterns" {
  description = "The path patterns for the listener rule"
  type        = list(string)
  default     = []
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

variable "requires_compatibilities" {
  description = "The launch type required for the task"
  type        = list(string)
}

variable "container_definitions" {
  description = "The JSON string that describes the container definitions for the task"
  type        = string
}

# Service Variables
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

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy for ECS service"
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
}

variable "launch_type" {
  description = "The launch template of the ECS cluster"
  type        = string
  default     = "FARGATE"
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
