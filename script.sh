#!/bin/bash
sudo yum update && yum upgrade -y
sudo yum install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx