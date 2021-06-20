#!/bin/bash
sudo apt-get install nginx -y
IPADR=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`
nginx_file=/etc/nginx/sites-available/odoo.conf
sudo su root -c "echo 'upstream odoo {
    server 127.0.0.1:8069 weight=1 fail_timeout=300s;
}
upstream odoo-im {
    server 127.0.0.1:8072 weight=1 fail_timeout=300s;
}
'" >> $nginx_file
echo """server {
    # server port and name
    listen 80;
    server_name    0.0.0.0;
""" >> $nginx_file
echo '
    # Specifies the maximum accepted body size of a client request, 
    # as indicated by the request header Content-Length. 
    client_max_body_size 200m;
    #log files
    access_log    /var/log/nginx/odoo-access.log;
    error_log    /var/log/nginx/odoo-error.log;
    
    proxy_connect_timeout       600;
    proxy_send_timeout          600;
    proxy_read_timeout          600;
    send_timeout                600;
    keepalive_timeout    600;
    
    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss application/rss+xml text/javascript image/svg+xml application/vnd.ms-fontobject application/x-font-ttf font/opentype image/bmp image/png image/gif image/jpeg image/jpg;
	
    # increase proxy buffer to handle some OpenERP web requests
    proxy_buffers 16 64k;
    proxy_buffer_size 128k;
    location / {
        proxy_pass    http://odoo;
        # force timeouts if the backend dies
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
	# Add Headers for odoo proxy mode
	# set headers
 	proxy_set_header X-Forwarded-Host $host;
 	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
 	proxy_set_header X-Forwarded-Proto $scheme;
 	proxy_set_header X-Real-IP $remote_addr;
        # by default, do not forward anything
        proxy_redirect off;
    }
    location /longpolling {
    	 proxy_pass    http://odoo-im;
	 proxy_set_header    Host            $host;
         proxy_set_header    X-Real-IP       $remote_addr;
         proxy_set_header    X-Forwarded-For $http_host;
    }
    # cache some static data in memory for 60mins.
    # under heavy load this should relieve stress on the web interface a bit.
    location ~* /web/static/ {
        proxy_cache_valid 200 60m;
        proxy_buffering    on;
        expires 864000;
        proxy_pass http://odoo;
    }
}' >> $nginx_file
sudo ln -s $nginx_file /etc/nginx/sites-enabled/
sudo service nginx restart
echo 'Dear Admin, We are ready for takeoff. Just Open http://'$IPADR
