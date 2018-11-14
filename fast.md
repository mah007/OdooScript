
 mkdir /etc/odoo
 
 mkdir /var/log/odoo
 
 touch /etc/odoo/odoo11.conf
 
 touch /etc/odoo/odoo12.conf
 
 touch /var/log/odoo/odoo11-server.log
 
 touch /var/log/odoo/odoo12-server.log
 
 chown odoo11:odoo11 /var/log/odoo/odoo11-server.log
 
 chown odoo12:odoo12 /var/log/odoo/odoo12-server.log
 
 chown odoo12:odoo12 /etc/odoo/odoo12.conf
 
 chown odoo11:odoo11 /etc/odoo/odoo11.conf
 
