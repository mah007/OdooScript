
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
 
 ---------------------------------------------
 
touch /etc/odoo/odoo.conf
 
touch /var/log/odoo/odoo-server.log
 
 
chown odoo:odoo /var/log/odoo/odoo-server.log
 
chown odoo:odoo /etc/odoo/odoo.conf
 
 
 sudo nano /etc/systemd/system/odoo.service
 
 sudo systemctl daemon-reload
 
 sudo systemctl enable odoo
 
 sudo systemctl start odoo
 
---------------------------------------------------

RewriteCond %{HTTP_HOST} =www.mah007.com

RewriteRule ^(.*) https://mah007.com/ [R]

RewriteCond %{SERVER_NAME} =mah007.com [OR]

RewriteCond %{SERVER_NAME} =webmail.mah007.com [OR]

RewriteCond %{SERVER_NAME} =admin.mah007.com [OR]

RewriteCond %{SERVER_NAME} =www.mah007.com

RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
wget -O win10.iso https://software-download.microsoft.com/db/Win10_20H2_v2_English_x64.iso?t=197a055d-f846-4ecc-8d42-1e8478ec3999&e=1611790557&h=44b9ccd1a5b0316150a8294319e24ab5
