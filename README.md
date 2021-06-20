# OdooScript
Odoo dependence installation script for Ubuntu 14.04 , 15.04 ,16.04 (universal)  
make your envirument ready for all kind of odoo with pycharm IDE
after run the script u have to download odoo manully 



### Copy this script and run it on your terminal 


export LC_ALL="en_US.UTF-8" <br />
export LC_CTYPE="en_US.UTF-8" <br />
sudo dpkg-reconfigure locales <br />

########################################################################<br />
adduser odoo

########################################################################<br />

apt-get update <br />
apt-get install software-properties-common <br />
add-apt-repository ppa:certbot/certbot <br />
apt-get update <br />
apt-get install python-certbot-apache <br />
sudo certbot --apache <br />
#######################################################################<br />

wget https://raw.githubusercontent.com/mah007/OdooScript/12.0/nginx.sh <br />
bash nginx.sh <br />

 apt-get update <br />
 apt-get install software-properties-common -y <br />
 add-apt-repository universe <br />
 add-apt-repository ppa:certbot/certbot <br />
 apt-get update <br />
 apt-get install certbot python-certbot-nginx -y<br />
 
 sudo certbot --nginx <br />



#######################################################################<br />

nano  /etc/apt/sources.list.d/pgdg.list <br />
deb deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main <br />
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - <br />

sudo apt-get update <br />

########################################################################<br />

sudo su - postgres -c "createuser -s odoo" 2> /dev/null || true <br />
wget https://raw.githubusercontent.com/mah007/OdooScript/master/odoo_pro.sh <br />
sudo /bin/sh odoo_pro.sh <br />

#

wget http://software.virtualmin.com/gpl/scripts/install.sh <br />
sh /root/install.sh -b LEMP <br />

********************PG UTF*********************<br />

sudo su postgres <br />
psql <br />
update pg_database set datistemplate=false where datname='template1'; <br />
drop database Template1; <br />
create database template1 with owner=postgres encoding='UTF-8' <br />
  lc_collate='en_US.utf8' lc_ctype='en_US.utf8' template template0; <br />
update pg_database set datistemplate=true where datname='template1'; <br />
