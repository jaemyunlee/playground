#!/bin/bash

yum install -y awslogs jq aws-cli

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
echo "ECS_CLUSTER=${cluster}" >> /etc/ecs/ecs.config

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_cloudwatch_logs.html
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = /var/log/dmesg
log_stream_name = ${cluster}/{container_instance_id}

[/var/log/messages]
file = /var/log/messages
log_group_name = /var/log/messages
log_stream_name = ${cluster}/{container_instance_id}
datetime_format = %b %d %H:%M:%S

[/var/log/docker]
file = /var/log/docker
log_group_name = /var/log/docker
log_stream_name = ${cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%S.%f

[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log
log_group_name = /var/log/ecs/ecs-init.log
log_stream_name = ${cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log.*
log_group_name = /var/log/ecs/ecs-agent.log
log_stream_name = ${cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/audit.log]
file = /var/log/ecs/audit.log.*
log_group_name = /var/log/ecs/audit.log
log_stream_name = ${cluster}/{container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ

EOF

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<- EOF
{
    "metrics": {
        "metrics_collected": {
            "statsd": {
                "service_address": ":8125",
                "metrics_collection_interval":60,
                "metrics_aggregation_interval":300
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ]
            }
        }
    }
}

EOF

region=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
sed -i -e "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf

cat > /etc/init/awslogjob.conf <<- EOF
description "Configure and start CloudWatch Logs agent on Amazon ECS container instance"
author "Amazon Web Services"
start on started ecs

script
	exec 2>>/var/log/ecs/cloudwatch-logs-start.log
	set -x

	until curl -s http://localhost:51678/v1/metadata
	do
		sleep 1
	done

	# Grab the cluster and container instance ARN from instance metadata
	cluster=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .Cluster')
	container_instance_id=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .ContainerInstanceArn' | awk -F/ '{print $2}' )

	# Replace the cluster name and container instance ID placeholders with the actual values
	sed -i -e "s/${cluster}/$cluster/g" /etc/awslogs/awslogs.conf
	sed -i -e "s/{container_instance_id}/$container_instance_id/g" /etc/awslogs/awslogs.conf

	service awslogs start
	chkconfig awslogs on
end script

EOF

start ecs