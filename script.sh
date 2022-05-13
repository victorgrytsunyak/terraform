#!/bin/bash
      sudo set -euo pipefail

      sudo export DEBIAN_FRONTEND=noninteractive
      sudo yum update -y && yum upgrade -y
      sudo yum install -y nginx
      sudo systemctl enable nginx
      sudo systemctl start nginx

      NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
      IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
      METADATA=$(curl -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=True" | jq 'del(.["startup-script"])')

      sudo cat <<EOF > /usr/share/nginx/html/index.html
<pre>
Name: $NAME
IP: $IP
Metadata: $METADATA
</pre>
EOF