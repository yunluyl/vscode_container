#!/bin/bash -e
#TODO(yun.lu): 1. support aws profile; 2. support instance IAM creation
if [[ -f /.dockerenv ]]; then
    echo "ERROR: please use this tool outside a docker container"
    exit 1
fi
TSP_USER_NAME="yun.lu"
INST_NAME="${TSP_USER_NAME}.vscode"
REGION=$(aws configure get region)
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
INST=$(aws --region ${REGION} ec2 describe-instances \
    --filters \
    "Name=tag:Name,Values=${INST_NAME}" \
    --output text)
if [[ -n "${INST}" ]]; then
    echo "Instance ${INST_NAME} already exist in region ${REGION} in account ${ACCOUNT}"
else
    aws --region "${REGION}" ec2 run-instances \
        --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
        --instance-type t3.xlarge \
        --count 1 \
        --subnet-id subnet-04147bbd79a3be98f \
        --security-group-ids sg-0650b69c5194d16d0 \
        --user-data file://aws_user_data.sh \
        --ebs-optimized \
        --block-device-mapping "[ { \"DeviceName\": \"/dev/xvda\", \"Ebs\": { \"VolumeSize\": 500 } } ]" \
        --iam-instance-profile Name=yunlu-ec2-admin \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INST_NAME}}]"

    PRIVATE_IP=$(aws --region ${REGION} ec2 describe-instances \
        --filters \
        "Name=instance-state-name,Values=pending" \
        "Name=tag:Name,Values=${INST_NAME}" \
        --query 'Reservations[*].Instances[*].[PrivateIpAddress]' \
        --output text)
    grep -v "vscode.tusimple.ai" /etc/hosts > /etc/hosts.new; mv /etc/hosts.new /etc/hosts
    echo "${PRIVATE_IP}    vscode.tusimple.ai" >> /etc/hosts
fi