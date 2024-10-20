#!/bin/bash
set -e  # Exit on any error

# Function to display colorful intro
function intro() {
    clear
    echo -e "\e[1;32m#############################################\e[0m"  # Green
    echo -e "\e[1;31m#                                           #\e[0m"  # Red
    echo -e "\e[1;34m#  WELCOME TO ODOO INSTALLING SCRIPT FOR    #\e[0m"  # Blue
    echo -e "\e[1;34m#           REDHAT 9 & ALMALINUX 9          #\e[0m"  # Blue
    echo -e "\e[1;31m#                                           #\e[0m"  # Red
    echo -e "\e[1;32m#############################################\e[0m"  # Green
    echo ""
    echo -e "\e[1;33mStarting the installation...\e[0m"  # Yellow
    sleep 3  # Pause for 3 seconds
}

# Call the intro function
intro

# Ask for Odoo version before doing anything
echo "Choose Odoo version (14.0, 15.0, 16.0, 17.0, 18.0):"
read odoo_version

# Get the hostname of the machine
hostname=$(hostname)

# Enable Code Ready Repository and Development Tools
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-x86_64-rpms
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git gcc redhat-rpm-config libxslt-devel bzip2-devel openldap-devel libjpeg-devel freetype-devel curl unzip openssl-devel wget yum-utils make libffi-devel zlib-devel tar libpq-devel python3.11 python3.11-devel python3.11-pip

# Set Python 3.11 as the default python3 alternative
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
sudo update-alternatives --config python3

# Set pip3.11 as the default pip3 and pip alternative
sudo update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip3.11 1
sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3.11 1
sudo update-alternatives --config pip3
sudo update-alternatives --config pip

# Install Python libraries via pip for Python 3.11
sudo python3.11 -m pip install --upgrade pip
sudo python3.11 -m pip install Babel beautifulsoup4 cffi cryptography dateutil docutils feedparser funcsigs gevent greenlet html2text html5lib jinja2 lxml mako MarkupSafe mock ofxparse pyopenssl passlib pbr pillow psutil psycopg2-binary pydot pygments pyparsing PyPDF2 renderpm reportlab roman serial stdnum suds-jurko pytz pyusb Werkzeug xlsxwriter pyyaml

# Install PostgreSQL from official repository
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql16-server postgresql16 postgresql16-devel
sudo /usr/pgsql-16/bin/postgresql-16-setup initdb
sudo systemctl enable --now postgresql-16

# Create a PostgreSQL user for Odoo
su - postgres -c "createuser -s $odoo_version"

# Install wkhtmltox
sudo yum install -y https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox-0.12.6.1-2.almalinux9.x86_64.rpm

# Install Node.js
sudo yum module install -y nodejs:18

# Create Odoo user and directories
sudo useradd -m -U -r -d /home/odoo -s /bin/bash odoo
sudo mkdir /odoo /odoo/extra
sudo chown -R odoo:odoo /odoo

# Clone Odoo from GitHub
sudo -u odoo git clone --depth 1 --branch $odoo_version https://www.github.com/odoo/odoo.git /odoo/odoo

# Create Odoo configuration directory and log file
sudo mkdir -p /etc/odoo /var/log/odoo
sudo touch /etc/odoo/odoo.conf /var/log/odoo/odoo-server.log
sudo chown -R odoo:odoo /etc/odoo /var/log/odoo

# Create Odoo configuration file
cat <<EOF | sudo tee /etc/odoo/odoo.conf
[options]
   ; admin password
   admin_passwd = admin
   db_host = False
   db_port = False
   db_user = odoo
   db_password = False
   addons_path = /odoo/odoo/addons,/odoo/extra
   logfile = /var/log/odoo/odoo-server.log
EOF

# Set up Odoo as a systemd service
cat <<EOF | sudo tee /etc/systemd/system/odoo.service
[Unit]
Description=Odoo
Documentation=http://www.odoo.com
After=network.target postgresql-16.service

[Service]
User=odoo
Group=odoo
ExecStart=/usr/bin/python3.11 /odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable Odoo service
sudo systemctl daemon-reload
sudo systemctl enable --now odoo

# Install the latest version of Nginx from official repository
sudo yum install -y epel-release
sudo yum install -y nginx
sudo systemctl enable --now nginx

# Create the Nginx configuration for Odoo
cat <<EOF | sudo tee /etc/nginx/conf.d/odoo.conf
# Odoo server
upstream odoo {
  server 127.0.0.1:8069;
}
upstream odoochat {
  server 127.0.0.1:8072;
}
map \$http_upgrade \$connection_upgrade {
  default upgrade;
  ''      close;
}

# HTTP to HTTPS redirection
server {
  listen 80;
  server_name $hostname;
  rewrite ^(.*) https://\$host\$1 permanent;
}

server {
  listen 443 ssl;
  server_name $hostname;
  proxy_read_timeout 720s;
  proxy_connect_timeout 720s;
  proxy_send_timeout 720s;
  client_max_body_size 1G;

  # SSL parameters
  ssl_certificate /etc/ssl/nginx/server.crt;
  ssl_certificate_key /etc/ssl/nginx/server.key;
  ssl_session_timeout 30m;
  ssl_protocols TLSv1.2;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
  ssl_prefer_server_ciphers off;

  # log
  access_log /var/log/nginx/odoo.access.log;
  error_log /var/log/nginx/odoo.error.log;

  # Redirect websocket requests to odoo gevent port
  location /websocket {
    proxy_pass http://odoochat;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;
    proxy_set_header X-Forwarded-Host \$http_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;
  }

  # Redirect requests to odoo backend server
  location / {
    # Add Headers for odoo proxy mode
    proxy_set_header X-Forwarded-Host \$http_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_redirect off;
    proxy_pass http://odoo;

    # Enable HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    # requires nginx 1.19.8
    proxy_cookie_flags session_id samesite=lax secure;
  }

  # common gzip
  gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
  gzip on;
}
EOF

# Restart Nginx to apply the configuration
sudo systemctl restart nginx

echo "Odoo $odoo_version and Nginx have been installed and configured with hostname $hostname!"
