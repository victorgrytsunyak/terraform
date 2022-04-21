#!/bin/bash
sudo yum update -y
  sudo yum install -y yum-utils
  sudo yum-config-manager -y \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
  sudo yum install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl start docker
  sudo docker run hello-world
  sudo yum install nginx -y