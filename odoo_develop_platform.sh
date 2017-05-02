#!/bin/bash
################################################################################
# Script for preparing Odoo developing platform on Ubuntu 14.04, 15.04 and 16.04 (could be used for other version too)
# Author:     Mahmoud Abdel Latif
# Mobile No:  +201002688172
# Email:      Mah008@me.com
# Website:    http://www.mah007.com
#-------------------------------------------------------------------------------
# This script will make ur computer ready for developing on ODOO
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo_developing.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo_developing.sh
# Execute the script to install Odoo:
# ./odoo-developing
################################################################################
 
##fixed parameters
#odoo instead of odoo use ur user name .EG OE_USER="mahmoud"
OE_USER="mahmoud"
#The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
#Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"

# Set this to True if you want to install Odoo 9 Enterprise! ( you can use enterprise normaly too ;) )
IS_ENTERPRISE="True"

##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltox installed, for a danger note refer to 
## https://www.odoo.com/documentation/8.0/setup/install.html#deb ):
WKHTMLTOX_X64=http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
WKHTMLTOX_X32=http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-i386.deb

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install default-jre
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get install default-jdk -y
sudo apt-get update
sudo apt-get install oracle-java8-installer -y
sudo add-apt-repository ppa:mystic-mirage/pycharm
sudo apt-get update


#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install wget subversion git bzr bzrtools python-pip gdebi-core -y
	
echo -e "\n---- Install python packages ----"
sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil -y
	
echo -e "\n---- Install python libraries ----"
sudo pip install gdata psycogreen
# This is for compatibility with Ubuntu 16.04. Will work on 14.04, 15.04 and 16.04
sudo -H pip install suds

echo -e "\n--- Install other required packages"
sudo apt-get install node-clean-css -y
sudo apt-get install node-less -y
sudo apt-get install python-gevent -y

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
else 
    echo -e "\n---- every thin is ready ----"
    
fi	



echo "-----------------------------------------------------------"
echo "Done! The Odoo developing platform is ready:"

echo "you can now install pycharm community of professional"

echo "using sudo apt-get install pycharm or pycharm-community"

echo "Restart restart ur computer and start developing and have fun ;)"
echo "-----------------------------------------------------------"
