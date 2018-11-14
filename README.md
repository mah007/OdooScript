# OdooScript
Odoo dependence installation script for Ubuntu 14.04 , 15.04 ,16.04 (universal)  
make your envirument ready for all kind of odoo with pycharm IDE
after run the script u have to download odoo manully 



### Copy this script and run it on your terminal 


export LC_ALL="en_US.UTF-8"

export LC_CTYPE="en_US.UTF-8"

sudo dpkg-reconfigure locales

########################################################################

apt-get update

apt-get install software-properties-common

add-apt-repository ppa:certbot/certbot

apt-get update

apt-get install python-certbot-apache 

sudo certbot --apache


#######################################################################

nano  /etc/apt/sources.list.d/pgdg.list

deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main


wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update

########################################################################

sudo su - postgres -c "createuser -s odoo" 2> /dev/null || true


wget https://raw.githubusercontent.com/mah007/OdooScript/master/odoo_pro.sh

sudo /bin/sh odoo_pro.sh

#
