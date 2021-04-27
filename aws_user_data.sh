#!/bin/bash -e
yum update -y
amazon-linux-extras install docker
service docker start
usermod -a -G docker ec2-user
chkconfig docker on
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 587413328198.dkr.ecr.us-west-2.amazonaws.com
docker run -d --name=code-server --init --network=host --restart=always --privileged -v /var/run/docker.sock:/var/run/docker.sock 587413328198.dkr.ecr.us-west-2.amazonaws.com/tsp-dev:latest