#!/bin/bash
sudo yum update -y && yum upgrade -y
sudo yum install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx