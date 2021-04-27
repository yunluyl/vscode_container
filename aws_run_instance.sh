#!/bin/bash -e
#TODO(yun.lu): 1. support aws profile; 2. support instance IAM creation; 3. support hardware and disk options; 4 automatically open browser

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
    echo "Instance ${INST_NAME} already exists in region ${REGION} in account ${ACCOUNT}"
    write_dns "${INST}"
    echo "Plase make sure your Tusimple VPN is connected, and go to https://${VSCODE_URL} in a browser"
    exit 0
fi

read -sp 'Set login password (you will use this to login to your vscode): ' PASSWORD
echo ""
if ! [[ ${#PASSWORD} -ge 6 && "${PASSWORD}" == *[A-Z]* && "${PASSWORD}" == *[a-z]* && "${PASSWORD}" == *[0-9]* ]]; then
    echo "ERROR: password needs to be at least 6 characters long, has at least 1 digit, uppercase letter, and lower case letter"
    exit 1
fi
read -sp 'Confirm login password : ' CONFIRM_PASSWORD
echo ""
if [[ "${PASSWORD}" != "${CONFIRM_PASSWORD}" ]]; then
    echo "ERROR: password and confirmation doesn't match"
    exit 1
fi
function sha256sum_universal() { shasum -a 256 "$@" ; } && export -f sha256sum_universal
PASSWORD_HASH=$(echo "${PASSWORD}" | sha256sum_universal | cut -d' ' -f1)
USER_DATA=`cat ./aws_user_data.sh`
USER_DATA="${USER_DATA} --hashed-password ${PASSWORD_HASH}"

echo "Creating new vscode instance..."
aws --region "${REGION}" ec2 run-instances \
    --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --instance-type t3.xlarge \
    --count 1 \
    --subnet-id subnet-04147bbd79a3be98f \
    --security-group-ids sg-0650b69c5194d16d0 \
    --user-data "${USER_DATA}" \
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
