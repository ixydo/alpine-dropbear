#!/usr/bin/env bash

set -eux

CLUSTER_ARN="$(curl -s "$ECS_CONTAINER_METADATA_URI_V4" | jq -Mr '.Labels["com.amazonaws.ecs.cluster"]')"
TASK_ARN="$(curl -s "$ECS_CONTAINER_METADATA_URI_V4" | jq -Mr '.Labels["com.amazonaws.ecs.task-arn"]')"
ENI_ID="$(aws ecs describe-tasks --cluster "$CLUSTER_ARN" --tasks "$TASK_ARN" | jq -Mr '.tasks[0].attachments[0].details[] | select(.name=="networkInterfaceId") | .value')"
PUBLIC_IP="$(aws ec2 describe-network-interfaces --network-interface-ids "$ENI_ID" | jq -Mr '.NetworkInterfaces[0].Association.PublicIp')"
aws servicediscovery register-instance --service-id "$CLOUD_MAP__SERVICE_ID" --instance-id "${TASK_ARN/*\//}" --attributes "AWS_INSTANCE_IPV4=$PUBLIC_IP"

exec /usr/sbin/dropbear -RFEwgsjk -G dbear -p 22
