#!/bin/bash
yum update -y
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user
chkconfig docker on
aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 587413328198.dkr.ecr.us-west-1.amazonaws.com
docker pull 587413328198.dkr.ecr.us-west-1.amazonaws.com/codeserver:latest
docker run -d --network=host --restart=always 587413328198.dkr.ecr.us-west-1.amazonaws.com/codeserver:latest
