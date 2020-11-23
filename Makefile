ECS_CLUSTER ?= default

.PHONY: clean
clean:
	docker rmi alpine-dropbear || :
	ssh-keygen -R '[localhost]:4834'

.PHONY: build
build:
	docker build -t alpine-dropbear .

.PHONY: up
up:
	docker run -it --rm -p 4834:22 alpine-dropbear

.PHONY: register-task-definition
register-task-definition:
	aws ecs register-task-definition --family alpine-dropbear --cli-input-json file://./task-definition.json

.PHONY: list-task-definitions
list-task-definitions:
	@aws ecs list-task-definitions --family-prefix alpine-dropbear

.PHONY: get-public-subnets
get-public-subnets:
	@aws ec2 describe-subnets --filters 'Name=tag:Tier,Values=public' --query 'Subnets[*].SubnetId' --output text | sed -e 's/\t\+/","/g'

.PHONY: get-security-group
get-security-group:
	@aws ec2 describe-security-groups --filters 'Name=ip-permission.to-port,Values=22' 'Name=ip-permission.cidr,Values=0.0.0.0/0' --output text --query 'SecurityGroups[0].GroupId'

.PHONY: run-task
run-task:
	aws ecs run-task \
		--cluster $(ECS_CLUSTER) \
		--launch-type FARGATE \
		--platform-version 1.4.0 \
		--network-configuration '{"awsvpcConfiguration":{"subnets":["$(shell make get-public-subnets)"],"securityGroups":["$(shell make get-security-group)"],"assignPublicIp":"ENABLED"}}' \
		--task-definition $(shell make list-task-definitions | jq -Mr '.taskDefinitionArns[-1]')

.PHONY: list-tasks
list-tasks:
	@aws ecs list-tasks --cluster $(ECS_CLUSTER) --family alpine-dropbear --output text --query 'taskArns'

.PHONY: get-url
get-url:
	@echo "Task URL: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/$(ECS_CLUSTER)/tasks/$(shell aws ecs describe-tasks --cluster $(ECS_CLUSTER) --tasks "$(shell make list-tasks)" --output text --query 'tasks[0].containers[0].runtimeId' | sed 's/-.*//' )/details"
