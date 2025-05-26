# ECS Service Terraform Module

Este módulo de Terraform implementa una arquitectura completa para desplegar servicios en AWS ECS Fargate, incluyendo repositorio ECR, balanceador de carga, autoescalado y monitoreo con CloudWatch.

## Recursos Incluidos

- **ECR Repository**: Almacena imágenes Docker con escaneo y cifrado habilitados.
- **ALB Target Group & Listener**: Configura el grupo de destino y el listener para el Application Load Balancer.
- **ECS Task Definition**: Define la tarea ECS con soporte para logs en CloudWatch.
- **ECS Service**: Despliega el servicio en ECS Fargate, conectado al ALB.
- **Auto Scaling**: Escalado automático basado en la utilización de CPU.
- **CloudWatch Logs & Alarms**: Monitoreo y alarmas para el uso de CPU.

## Variables Principales

| Variable                      | Descripción                                 | Ejemplo                |
|-------------------------------|---------------------------------------------|------------------------|
| `service_name`                | Nombre del servicio                         | `"my-service"`         |
| `cluster_name`                | Nombre del cluster ECS                      | `"my-cluster"`         |
| `cpu`, `ram`                  | Recursos asignados a la tarea               | `256`, `512`           |
| `service_port`                | Puerto expuesto por el contenedor           | `8080`                 |
| `vpc_id`                      | ID de la VPC                                | `"vpc-xxxxxx"`         |
| `subnet_ids`                  | Lista de subnets                            | `["subnet-xxx"]`       |
| `security_group_id`           | ID del Security Group                       | `"sg-xxxxxx"`          |
| `desired_task`                | Número de tareas deseadas                   | `2`                    |
| `min_capacity`, `max_capacity`| Límites de autoescalado                     | `1`, `5`               |
| `cpu_high_threshold`          | Umbral alto de CPU para escalar             | `80`                   |
| `cpu_low_threshold`           | Umbral bajo de CPU para reducir             | `20`                   |
| `tags`                        | Tags para los recursos                      | `{ Environment = "dev" }` |

## Uso

```hcl
module "ecs_service" {
    source                = "./tf-module-ecs-service"
    service_name          = "my-service"
    cluster_name          = "my-cluster"
    cpu                   = 256
    ram                   = 512
    service_port          = 8080
    vpc_id                = "vpc-xxxxxx"
    subnet_ids            = ["subnet-xxx"]
    security_group_id     = "sg-xxxxxx"
    desired_task          = 2
    min_capacity          = 1
    max_capacity          = 5
    cpu_high_threshold    = 80
    cpu_low_threshold     = 20
    tags                  = { Environment = "dev" }
    # ...otras variables necesarias
}
```

## Requisitos

- Terraform >= 1.0
- AWS Provider >= 4.0

## Salidas

- `ecr_repository_url`
- `ecs_service_name`
- `alb_dns_name`
- `cloudwatch_log_group`

## Licencia

MIT