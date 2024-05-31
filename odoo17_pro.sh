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
billboard_message="Welcome to the Odoo Production Server Setup Script!"
display_billboard "$billboard_message"

# Prompt user for Odoo version
select_odoo_version

# Fixed parameters
OE_USER="odoo"

# Add group
groupadd "$OE_USER"
# Add user
useradd --create-home -d /home/"$OE_USER" --shell /bin/bash -g "$OE_USER" "$OE_USER"
# Add user to sudoers
usermod -aG sudo "$OE_USER"

# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
# Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"

# Set this to True if you want to install Odoo 9 10 11 12 13 14Enterprise! (you can use enterprise normally too)
IS_ENTERPRISE="True"

# WKHTMLTOPDF download links
WKHTMLTOX_X64="https://github.com/odoo/wkhtmltopdf/releases/download/nightly/odoo-wkhtmltopdf-ubuntu-jammy-x86_64-0.13.0-nightly.deb"
WKHTMLTOX_X32="https://github.com/odoo/wkhtmltopdf/releases/download/nightly/odoo-wkhtmltopdf-ubuntu-jammy-x86_64-0.13.0-nightly.deb"

# Update Server
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y
apt install -y zip gdebi net-tools
echo "----------------------------localization-------------------------------"

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
sudo dpkg-reconfigure locales

# Install PostgreSQL Server
sudo sh -c 'echo "deb [arch=amd64] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -o setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh
sh setup-repos.sh

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update

echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql-15 postgresql-server-dev-15 -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

# Install Dependencies
echo -e "\n---- Install tool packages ----"
sudo apt install -y git python3-pip build-essential wget python3-dev python3-venv python3-wheel libfreetype6-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev libxslt1-dev libldap2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev
echo -e "\n---- Install python libraries ----"
sudo pip install gdata psycogreen
sudo -H pip install suds

echo -e "\n--- Install other required packages"
sudo apt-get install node-clean-css -y
sudo apt-get install node-less -y
sudo apt-get install python-gevent -y
sudo apt-get install libcairo2-dev python3-cairo -y
pip3 install rlPyCairo
apt-get install libwww-perl -y

# Install Wkhtmltopdf if needed
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
    echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 15.0 ----"
    if [ "`getconf LONG_BIT`" == "64" ];then
        _url=$WKHTMLTOX_X64
    else
        _url=$WKHTMLTOX_X32
    fi
    sudo wget $_url
    sudo gdebi --n `basename $_url`
else
    echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi

# Odoo Enterprise install
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt-get install nodejs -y

echo -e "\n---- Installing Enterprise specific libraries ----"
sudo npm install -g less
sudo npm install -g less-plugin-clean-css
sudo npm install -g rtlcss

echo -e "\n---- everything is ready ----"

sudo ln -s /usr/bin/nodejs /usr/bin/node

sudo apt-get install -y python3-dev
sudo easy_install greenlet
sudo easy_install gevent
sudo apt-get install -y python3-pip python3-wheel python3-setuptools
sudo -H pip3 install --upgrade pip
sudo apt install -y python3-asn1crypto 
sudo apt install -y python3-babel python3-bs4 python3-cffi-backend python3-cryptography python3-dateutil python3-docutils python3-feedparser python3-funcsigs python3-gevent python3-greenlet python3-html2text python3-html5lib python3-jinja2 python3-lxml python3-mako python3-markupsafe python3-mock python3-ofxparse python3-openssl python3-passlib python3-pbr python3-pil python3-psutil python3-psycopg2 python3-pydot python3-pygments python3-pyparsing python3-pypdf2 python3-renderpm python3-reportlab python3-reportlab-accel python3-roman python3-serial python3-stdnum python3-suds python3-tz python3-usb python3-werkzeug python3-xlsxwriter python3-yaml
pip3 install -r https://raw.githubusercontent.com/odoo/odoo/"$OE_BRANCH"/requirements.txt --user
pip3 install phonenumbers --user

mkdir /odoo
mkdir /etc/odoo
mkdir /var/log/odoo
touch /etc/odoo/odoo.conf
touch /var/log/odoo/odoo-server.log
chown odoo:odoo /var/log/odoo/odoo-server.log
chown odoo:odoo /etc/odoo/odoo.conf
cd /odoo

sudo git clone --depth 1 --branch "$OE_BRANCH" https://www.github.com/odoo/odoo 
cd /

chown -R odoo:odoo /odoo

cd /root
wget https://raw.githubusercontent.com/mah007/OdooScript/14.0/odoo.service
cp odoo.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable odoo
sudo systemctl start odoo
wget https://raw.githubusercontent.com/mah007/OdooScript/14.0/nginx.sh
bash nginx.sh
apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
wget https://download.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
apt-get install apt-transport-https -y
apt-get update
apt-get install -y webmin --install-recommends 

echo "-----------------------------------------------------------"
echo "Done! The Odoo production platform is ready:"
echo "Restart your computer and start developing. Have fun! ;)"
echo "-----------------------------------------------------------"
