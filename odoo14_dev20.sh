#!/bin/bash
# to run the script "sudo /bin/sh odoo_pro.sh"
################################################################################
# Script for preparing Odoo production server platform on Ubuntu 20.04 (could be used for other version too)
# Author:     Mahmoud Abdel Latif
# Mobile No:  +201002688172
# Email:      Mah008@me.com
# Website:    http://www.mah007.com
#-------------------------------------------------------------------------------
# This script will make ur server ready for installing ODOO from 8 to 14
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo_pro.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo_pro.sh
# git clone --depth 1 --branch 10.0 https://www.gitlab.com/mah007/odoo .
# Execute the script to install Odoo:
# ./odoo-developing
################################################################################
 
##fixed parameters
#instead of odoo use ur user name .EG OE_USER="mahmoud"
OE_USER="mahmoud"
OE_BRANCH="14.0"
#The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
#Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"

# Set this to True if you want to install Odoo 9 10 11 12 13 14Enterprise! ( you can use enterprise normaly too ;) )
IS_ENTERPRISE="True"

##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltox installed, for a danger note refer to 
## https://www.odoo.com/documentation/8.0/setup/install.html#deb ):
WKHTMLTOX_X64=https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb
WKHTMLTOX_X32=https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_i386.deb
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y
apt install -y zip
echo "----------------------------localization-------------------------------"

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
sudo dpkg-reconfigure locales

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt focal-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update

echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql-13 postgresql-server-dev-13 -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt install git python3-pip build-essential wget python3-dev python3-venv python3-wheel libfreetype6-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev libxslt1-dev libldap2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev
echo -e "\n---- Install python libraries ----"
sudo pip install gdata psycogreen
# This is for compatibility with Ubuntu 16.04. Will work on 14.04, 15.04 and 16.04
sudo -H pip install suds

echo -e "\n--- Install other required packages"
sudo apt-get install node-clean-css -y
sudo apt-get install node-less -y
sudo apt-get install python-gevent -y
apt-get install libwww-perl -y
#sudo apt install ifupdown -y


#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 9 ----"
  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url
  sudo gdebi --n `basename $_url`
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi
	



if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
	
    echo -e "\n---- Installing Enterprise specific libraries ----"
    sudo apt-get install nodejs npm -y
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
    sudo npm install -g rtlcss
else 
    echo -e "\n---- every thing is ready ----"
    
fi	
  sudo ln -s /usr/bin/nodejs /usr/bin/node
  
sudo apt-get install -y python3-dev
sudo easy_install greenlet
sudo easy_install gevent
sudo apt-get install -y python3-pip python3-wheel python3-setuptools
sudo -H pip3 install --upgrade pip
sudo -H pip3 install -r https://raw.githubusercontent.com/odoo/odoo/14.0/requirements.txt
sudo apt install -y python3-asn1crypto 
sudo apt install -y python3-babel python3-bs4 python3-cffi-backend python3-cryptography python3-dateutil python3-docutils python3-feedparser python3-funcsigs python3-gevent python3-greenlet python3-html2text python3-html5lib python3-jinja2 python3-lxml python3-mako python3-markupsafe python3-mock python3-ofxparse python3-openssl python3-passlib python3-pbr python3-pil python3-psutil python3-psycopg2 python3-pydot python3-pygments python3-pyparsing python3-pypdf2 python3-renderpm python3-reportlab python3-reportlab-accel python3-roman python3-serial python3-stdnum python3-suds python3-tz python3-usb python3-vatnumber python3-werkzeug python3-xlsxwriter python3-yaml
sudo -H pip3 install -r https://raw.githubusercontent.com/odoo/odoo/11.0/requirements.txt
sudo -H pip3 install -r https://raw.githubusercontent.com/odoo/odoo/12.0/requirements.txt
sudo -H pip3 install -r https://raw.githubusercontent.com/odoo/odoo/13.0/requirements.txt
sudo -H pip3 install -r https://raw.githubusercontent.com/odoo/odoo/14.0/requirements.txt
sudo -H pip3 install -r https://raw.githubusercontent.com/mah007/OdooScript/14.0/requirements.txt
sudo -H pip3 install phonenumbers
echo "---------------------------odoo directory--------------------------------"
# mkdir /odoo
# mkdir /etc/odoo
# mkdir /var/log/odoo
# touch /etc/odoo/odoo.conf
# touch /var/log/odoo/odoo-server.log
# chown odoo:odoo /var/log/odoo/odoo-server.log
# chown odoo:odoo /etc/odoo/odoo.conf
# cd /odoo

# sudo git clone --depth 1 --branch $OE_BRANCH https://www.github.com/odoo/odoo 
# cd /

# chown -R odoo:odoo /odoo

# cd /root
# echo "-------------------------------odoo service----------------------------"
# wget https://raw.githubusercontent.com/mah007/OdooScript/14.0/odoo.service
# cp odoo.service /etc/systemd/system
# sudo systemctl daemon-reload
# sudo systemctl enable odoo
# sudo systemctl start odoo
# echo "----------------------------NGINX-------------------------------"
# wget https://raw.githubusercontent.com/mah007/OdooScript/14.0/nginx.sh
# bash nginx.sh
# echo "---------------------------webmin--------------------------------"
# apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
# wget https://download.webmin.com/jcameron-key.asc
# apt-key add jcameron-key.asc
# apt-get install apt-transport-https -y
# apt-get update
# apt-get install webmin -y


echo "-----------------------------------------------------------"
echo "Done! The Odoo production platform is ready:"

echo "Restart restart ur computer and start developing and have fun ;)"
echo "-----------------------------------------------------------"
