#!/bin/bash -e
#TODO(yun.lu): 1. support aws profile; 2. support instance IAM creation
if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit 1
fi
if [[ -f /.dockerenv ]]; then
    echo "ERROR: please use this tool outside of a docker container"
    exit 1
fi

VSCODE_URL="vscode.tusimple.ai"

write_dns () {
    grep -v "${VSCODE_URL}" /etc/hosts > /etc/hosts.new; mv /etc/hosts.new /etc/hosts
    echo "$1    ${VSCODE_URL}" >> /etc/hosts
}

TSP_USER_NAME="${SUDO_USER}"
INST_NAME="${TSP_USER_NAME}.vscode"
echo "Using default AWS region..."
REGION=$(aws configure get region)
echo "Geting AWS account information..."
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "Checking if vscode instance ${INST_NAME} exists..."
INST=$(aws --region ${REGION} ec2 describe-instances \
    --filters \
    "Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped" \
    "Name=tag:Name,Values=${INST_NAME}" \
    --query 'Reservations[*].Instances[*].[PrivateIpAddress]' \
    --output text)
if [[ -n "${INST}" ]]; then
    echo "Instance ${INST_NAME} already exist in region ${REGION} in account ${ACCOUNT}"
    write_dns "${INST}"
    echo "Plase make sure your Tusimple VPN is connected, and go to https://${VSCODE_URL} in a browser"
    exit 0
fi
echo "Creating new vscode instance..."
aws --region "${REGION}" ec2 run-instances \
    --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --instance-type t3.xlarge \
    --count 1 \
    --subnet-id subnet-04147bbd79a3be98f \
    --security-group-ids sg-0650b69c5194d16d0 \
    --user-data file://aws_user_data.sh \
    --ebs-optimized \
    --block-device-mapping "[ { \"DeviceName\": \"/dev/xvda\", \"Ebs\": { \"VolumeSize\": 500, \"Encrypted\": true } } ]" \
    --iam-instance-profile Name=yunlu-ec2-admin \
    --hibernation-options Configured=true \
    --output text \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INST_NAME}}]"
echo "Fetching vscode instance address..."
PRIVATE_IP=$(aws --region ${REGION} ec2 describe-instances \
    --filters \
    "Name=instance-state-name,Values=pending,running" \
    "Name=tag:Name,Values=${INST_NAME}" \
    --query 'Reservations[*].Instances[*].[PrivateIpAddress]' \
    --output text)
write_dns "${PRIVATE_IP}"
echo "vscode instance is created, please make sure your Tusimple VPN is connected, and go to https://${VSCODE_URL} in a browser"
