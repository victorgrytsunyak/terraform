#!/bin/bash
sudo apt-get update && apt-get upgrade -y
sudo apt-get install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx