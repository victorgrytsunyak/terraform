#!/bin/bash
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo docker run hello-world
sudo apt-get install nginx -y