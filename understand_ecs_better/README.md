Today, service discovery is available for Amazon ECS tasks using AWS Fargate or the EC2 launch type with awsvpc networking mode

If the task definition your service task specifies uses the awsvpc network mode, you can create any combination of A or SRV records for each service task. If you use SRV records, a port is required.

If the task definition that your service task specifies uses the bridge or host network mode, an SRV record is the only supported DNS record type. Create an SRV record for each service task. The SRV record must specify a container name and container port combination from the task definition.