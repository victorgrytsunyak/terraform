FROM ubuntu:20.04
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install sudo -y && \
    useradd docker && \
    mkdir -p /home/docker && chown -R docker:sudo /home/docker && \
    usermod -aG sudo docker && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER docker

RUN sudo apt-get install telnet -y && \
    sudo apt-get install net-tools -y && \
    sudo apt-get install nginx -y && \
    sudo apt-get install curl -y && \
    sudo mkdir -p /var/www/html && \
    sudo rm -rf /var/www/html/index.nginx-debian.html
COPY index.html ZiClJf-1920w.jpg  /var/www/html/
COPY azimuth /etc/nginx/sites-available/
RUN sudo ln -s /etc/nginx/sites-available/azimuth /etc/nginx/sites-enabled/
EXPOSE 80
CMD ["sudo", "nginx", "-g", "daemon off;"] 