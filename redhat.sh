#!/bin/bash

# Function to display colorful billboard message
display_billboard() {
    printf "\e[91m\e[1m==================================================\e[0m\n"
    printf "\e[93m\e[1m%s\e[0m\n" "$1"
    printf "\e[91m\e[1m==================================================\e[0m\n"
}

# Function to prompt user for Odoo version
select_odoo_version() {
    echo "Please select the Odoo version:"
    echo "1) Odoo 14.0"
    echo "2) Odoo 15.0"
    echo "3) Odoo 16.0"
    echo "4) Odoo 17.0"
    read -rp "Enter your choice (1-4): " choice

    case $choice in
        1) OE_BRANCH="14.0";;
        2) OE_BRANCH="15.0";;
        3) OE_BRANCH="16.0";;
        4) OE_BRANCH="17.0";;
        *) echo "Invalid choice. Please enter a number between 1 and 4."; exit 1;;
    esac
}

# Display billboard message
billboard_message="Welcome to the Odoo Production Server Setup Script for Red Hat 9!"
display_billboard "$billboard_message"

# Prompt user for Odoo version
select_odoo_version

# Fixed parameters
OE_USER="odoo"

# Add user group
groupadd "$OE_USER"
# Add user
useradd --create-home -d /home/"$OE_USER" --shell /bin/bash -g "$OE_USER" "$OE_USER"
# Add user to sudoers
usermod -aG wheel "$OE_USER"

# The default port where this Odoo instance will run under
INSTALL_WKHTMLTOPDF="True"

# Set to True if you want to install Odoo Enterprise
IS_ENTERPRISE="True"

# WKHTMLTOPDF download links
WKHTMLTOX_X64="https://github.com/odoo/wkhtmltopdf/releases/download/nightly/odoo-wkhtmltopdf-fedora-39-x86_64-0.13.0-nightly.rpm"

# Update Server
echo -e "\n---- Update Server ----"
sudo dnf update -y
sudo dnf install -y epel-release zip net-tools

# Install PostgreSQL
echo -e "\n---- Install PostgreSQL Server ----"
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf install -y postgresql15 postgresql15-server postgresql15-contrib postgresql15-devel

# Initialize PostgreSQL
sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
sudo systemctl enable postgresql-15
sudo systemctl start postgresql-15

# Create PostgreSQL User for Odoo
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

# Install dependencies
echo -e "\n---- Install tool packages ----"
sudo dnf install -y git python3-pip gcc wget python3-devel libxslt-devel bzip2-devel openldap-devel libjpeg-devel zlib-devel libpq-devel openjpeg2-devel \
libtiff-devel libwebp-devel freetype-devel harfbuzz-devel fribidi-devel cairo-devel
sudo dnf groupinstall "Development Tools" -y

# Install python libraries
echo -e "\n---- Install Python libraries ----"
pip3 install --upgrade setuptools wheel
pip3 install psycopg2-binary pillow babel lxml decorator passlib werkzeug html2text xlwt openpyxl requests phonenumbers

# Install Node.js
echo -e "\n---- Install Node.js ----"
sudo dnf module install -y nodejs:20
sudo npm install -g less less-plugin-clean-css rtlcss

# Install Wkhtmltopdf if needed
if [ "$INSTALL_WKHTMLTOPDF" = "True" ]; then
    echo -e "\n---- Install wkhtmltopdf ----"
    wget $WKHTMLTOX_X64
    sudo dnf install -y `basename $WKHTMLTOX_X64`
else
    echo "Wkhtmltopdf isn't installed due to user choice."
fi

# Install Odoo from GitHub
echo -e "\n---- Installing Odoo from GitHub ----"
mkdir /odoo
mkdir /etc/odoo
mkdir /var/log/odoo
touch /etc/odoo/odoo.conf
touch /var/log/odoo/odoo-server.log
chown odoo:odoo /var/log/odoo/odoo-server.log
chown odoo:odoo /etc/odoo/odoo.conf
cd /odoo

sudo git clone --depth 1 --branch "$OE_BRANCH" https://www.github.com/odoo/odoo 
chown -R odoo:odoo /odoo

# Create Odoo systemd service
echo -e "\n---- Create Odoo Service ----"
cat <<EOF | sudo tee /etc/systemd/system/odoo.service
[Unit]
Description=Odoo ERP
Documentation=https://www.odoo.com
After=network.target postgresql-15.service

[Service]
Type=simple
User=$OE_USER
ExecStart=/odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo

# Install Nginx from the official repository
echo -e "\n---- Install Nginx ----"
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://nginx.org/packages/rhel/9/x86_64/nginx.repo
sudo dnf install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Fetch the current hostname
HOSTNAME=$(hostname -f)

# Generate a self-signed SSL certificate
echo -e "\n---- Generating Self-Signed SSL Certificate ----"
sudo mkdir -p /etc/ssl/nginx
sudo openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=US/ST=SomeState/L=SomeCity/O=SomeOrganization/OU=IT/CN=$HOSTNAME" \
    -keyout /etc/ssl/nginx/server.key -out /etc/ssl/nginx/server.crt

# Create Nginx configuration file with dynamic hostname
echo -e "\n---- Configuring Nginx ----"
cat <<EOF | sudo tee /etc/nginx/conf.d/odoo.conf
#odoo server
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

# http -> https
server {
  listen 80;
  server_name $HOSTNAME;
  rewrite ^(.*) https://\$host\$1 permanent;
}

server {
  listen 443 ssl;
  server_name $HOSTNAME;
  proxy_read_timeout 720s;
  proxy_connect_timeout 720s;
  proxy_send_timeout 720s;
  client_max_body_size 1G;

  # SSL parameters
  ssl_certificate /etc/ssl/nginx/server.crt;
  ssl_certificate_key /etc/ssl/nginx/server.key;
  ssl_session_timeout 30m;
  ssl_protocols TLSv1.2;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
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

# Restart Nginx to apply changes
sudo systemctl restart nginx

# Configure firewall
echo -e "\n---- Configuring Firewall ----"
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --reload

echo "-----------------------------------------------------------"
echo "Done! The Odoo production platform is ready on Red Hat 9:"
echo "You can start developing. Have fun!"
echo "-----------------------------------------------------------"
