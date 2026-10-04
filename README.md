# Enhanced Odoo Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04%20LTS-orange.svg)](https://ubuntu.com/)
[![Odoo](https://img.shields.io/badge/Odoo-14.0%20to%2020.0-purple.svg)](https://www.odoo.com/)
[![Nginx](https://img.shields.io/badge/Nginx-Latest-green.svg)](https://nginx.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)

> **Professional Odoo installation scripts with domain configuration, official Nginx, SSL certificates, and dynamic configuration generation for Ubuntu 22.04 and 24.04**

## 🚀 Quick Start

### Ubuntu 24.04 (recommended, Odoo 15.0 to 20.0)

```bash
# Download the installer
wget https://raw.githubusercontent.com/mah007/OdooScript/refs/heads/main/odoo_installer_24.sh
# Make it executable
chmod +x odoo_installer_24.sh

# Run the installer
sudo ./odoo_installer_24.sh
```

### Ubuntu 22.04 (Odoo 14.0 to 18.0)

```bash
wget https://raw.githubusercontent.com/mah007/OdooScript/refs/heads/main/odoo_installer.sh
chmod +x odoo_installer.sh
sudo ./odoo_installer.sh
```

### Which script should I use?

| | `odoo_installer_24.sh` | `odoo_installer.sh` |
|---|---|---|
| Ubuntu | 24.04 LTS (Noble) | 22.04 LTS (Jammy) |
| Odoo versions | 15.0 – 20.0 (14.0 offered with a warning) | 14.0 – 18.0 |
| Editions | Community and Enterprise | Community |
| Python | Virtual environment at `/odoo/python` (Python 3.12) | System Python with `pip --user` |
| Webmin | Optional | – |
| Steps | 9 | 8 |

> Run the installers on a fresh server only. They upgrade system packages, replace any existing Nginx, and create an `odoo` system user.

## 📋 Table of Contents

- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Installation Process](#-installation-process)
- [Technical Architecture](#-technical-architecture)
- [Configuration Options](#-configuration-options)
- [SSL Certificate Management](#-ssl-certificate-management)
- [Nginx Configuration](#-nginx-configuration)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

### 🌐 **Domain & DNS Management**
- Interactive domain configuration with validation
- Automatic DNS verification and IP detection
- Support for both domain-based and IP-based installations
- Graceful fallback for DNS misconfigurations

### 🔧 **Official Nginx Installation**
- Latest Nginx version from official nginx.org repository (1.20.5+)
- Automatic removal of outdated Ubuntu stock versions
- Proper repository configuration with signing keys
- Modern SSL/TLS configuration with security headers

### 🔒 **SSL Certificate Automation**
- **Let's Encrypt**: Automated certificate generation with Certbot
- **Self-signed**: Fallback certificates for testing environments
- Automatic certificate renewal setup
- Modern TLS 1.2/1.3 configuration

### ⚙️ **Dynamic Configuration**
- Native Odoo configuration generation using `odoo-bin --save`
- Clean configuration without forced master passwords
- Automatic proxy mode detection for Nginx setups
- Automatic worker count behind Nginx (2 × CPUs + 1, capped by RAM) so live chat and notifications work over the websocket (24.04)
- Secure file permissions and ownership

### 🏢 **Odoo Editions** (24.04)
- **Community**: cloned from `github.com/odoo/odoo`
- **Enterprise**: cloned from `github.com/odoo/enterprise` with your GitHub username and Personal Access Token (the account needs access to the Odoo Enterprise repository)
- Credentials are verified before installation starts, are not written to the install log, and are removed from the cloned repository's Git config
- Falls back to Community if the Enterprise clone fails

### 🐧 **Ubuntu 24.04 Support** (`odoo_installer_24.sh`)
- Isolated Python virtual environment at `/odoo/python` (Ubuntu 24.04 blocks system-wide `pip` installs)
- Optional **Webmin** web administration on port 10000, using the Let's Encrypt certificate when available
- `rtlcss` installed for right-to-left languages (Arabic, Hebrew) in both editions
- wkhtmltopdf for amd64 and arm64 servers
- Safe to re-run after a failure: an existing Odoo checkout of the same version is reused

### 🛡️ **Enterprise-Grade Security**
- Comprehensive error handling with graceful degradation
- Detailed logging and audit trails
- Secure user and permission management
- Modern cryptographic standards

### 📊 **Advanced Monitoring**
- Real-time progress tracking with visual indicators
- Multi-level logging (DEBUG, INFO, WARNING, ERROR)
- Installation validation and health checks
- Comprehensive installation reports

## 🖥️ System Requirements

### **Operating System**
- Ubuntu 24.04 LTS (Noble Numbat) with `odoo_installer_24.sh`
- Ubuntu 22.04 LTS (Jammy Jellyfish) with `odoo_installer.sh`
- Root or sudo privileges required

### **Hardware Requirements**
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 2GB | 4GB+ |
| Storage | 10GB | 20GB+ |
| CPU | 1 core | 2+ cores |

### **Network Requirements**
- Internet connection for package downloads
- Domain name (optional, IP fallback available)
- Open ports: 80 (HTTP), 443 (HTTPS), 8069 (Odoo direct), 10000 (Webmin, optional)

## 🔄 Installation Process

The 22.04 installer follows the 8-step automated process below. The 24.04 installer runs 9 steps: it adds **Python Environment Setup** after the database step (creates the virtual environment at `/odoo/python`) and **Webmin Installation** as the last step.

### **Step 1: Pre-flight Checks**
- System requirements validation
- Ubuntu version verification
- Disk space and memory checks
- Internet connectivity testing

### **Step 2: System Preparation**
- User and group creation (`odoo` user)
- System package updates
- Locale configuration
- Basic tool installation

### **Step 3: Database Setup**
- PostgreSQL 16 installation from official repository
- Database user configuration
- Service enablement and startup
- Connection testing

### **Step 4: Dependencies Installation**
- System libraries and build tools needed by Odoo's Python packages
- Fonts used by Odoo reports and the web client
- Node.js 20 and `rtlcss` (right-to-left languages)
- Odoo-specific dependencies

### **Step 5: Wkhtmltopdf Installation**
- PDF generation library installation
- Architecture detection (x64/x32)
- Version verification
- Integration testing

### **Step 6: Odoo Installation**
- Source code download from official repository (Community, plus Enterprise when selected on 24.04)
- Python requirements installation (into the virtual environment on 24.04)
- Directory structure creation
- Permission configuration

### **Step 7: Service Configuration**
- Systemd service file creation
- Nginx installation and configuration
- SSL certificate generation/installation
- Service enablement

### **Step 8: Final Setup**
- Installation validation
- Service health checks
- Report generation
- Success confirmation

## 🏗️ Technical Architecture

### **Core Components**

```
Enhanced Odoo Installer
├── Configuration Management
│   ├── Domain validation and DNS checking
│   ├── SSL certificate type selection
│   └── Dynamic Odoo configuration generation
├── Package Management
│   ├── Official repository integration
│   ├── Dependency resolution
│   └── Version compatibility checking
├── Service Management
│   ├── Systemd service configuration
│   ├── Process monitoring
│   └── Automatic startup configuration
└── Security Framework
    ├── User privilege management
    ├── File permission enforcement
    └── SSL/TLS implementation
```

### **Script Structure**

```bash
odoo_installer.sh
├── Global Variables & Configuration
├── Utility Functions
│   ├── Logging system
│   ├── Progress tracking
│   ├── Error handling
│   └── User interaction
├── Validation Functions
│   ├── System requirements
│   ├── Network connectivity
│   └── Version compatibility
├── Installation Functions
│   ├── step_preflight_checks()
│   ├── step_system_preparation()
│   ├── step_database_setup()
│   ├── step_dependencies_installation()
│   ├── step_wkhtmltopdf_installation()
│   ├── step_odoo_installation()
│   ├── step_service_configuration()
│   └── step_final_setup()
├── Nginx & SSL Functions
│   ├── install_official_nginx()
│   ├── generate_self_signed_ssl()
│   ├── install_letsencrypt_ssl()
│   └── create_nginx_odoo_config()
└── Main Execution Flow
```

## ⚙️ Configuration Options

### **Odoo Versions Supported**

| Odoo | Ubuntu 24.04 | Ubuntu 22.04 | Notes |
|---|---|---|---|
| 14.0 | ⚠️ | ✅ | Its pinned Python packages do not build on Python 3.12; use 22.04 |
| 15.0 | ✅ | ✅ | |
| 16.0 | ✅ | ✅ | |
| 17.0 | ✅ | ✅ | |
| 18.0 | ✅ | ✅ | |
| 19.0 | ✅ | – | |
| 20.0 | ✅ | – | Requires Python 3.12+ and PostgreSQL 16+ (both installed by the 24.04 script) |

### **Installation Modes**

#### **Domain-based Installation**
```bash
# User provides domain name
Domain: odoo.example.com
SSL: Let's Encrypt (automatic)
Access: https://odoo.example.com
```

#### **IP-based Installation**
```bash
# No domain provided
Domain: Server IP address
SSL: Self-signed certificate
Access: https://[server-ip]
```

### **Generated Configuration Files**

#### **Odoo Configuration (`/etc/odoo/odoo.conf`)**

The installer writes these settings, then runs `odoo-bin --save` so Odoo adds the full list of options with their defaults:

```ini
[options]
db_host = False
db_port = False
db_user = odoo
db_password = False
; /odoo/enterprise is added for Enterprise installs
addons_path = /odoo/odoo/addons,/odoo/enterprise
logfile = /var/log/odoo/odoo-server.log
log_level = info
; True when Nginx is installed
proxy_mode = True
; 24.04 with Nginx: 2 x CPUs + 1, capped by RAM (minimum 2). 0 without Nginx
workers = 5
```

#### **Systemd Service (`/etc/systemd/system/odoo.service`)**
```ini
[Unit]
Description=Odoo
Documentation=http://www.odoo.com
Requires=postgresql.service
After=postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
```

On Ubuntu 24.04 the service runs Odoo with the virtual environment's Python:

```ini
ExecStart=/odoo/python/bin/python /odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf
```

## 🔒 SSL Certificate Management

### **Let's Encrypt Integration**

The installer uses Certbot via snapd for Let's Encrypt certificates:

```bash
# Automatic installation process
1. Install snapd (if not present)
2. Install certbot via snap
3. Create temporary Nginx configuration
4. Obtain SSL certificate
5. Configure automatic renewal
6. Update Nginx configuration
```

#### **Certificate Renewal**
```bash
# Test renewal (dry run)
certbot renew --dry-run

# Manual renewal
certbot renew

# Automatic renewal (configured by installer)
systemctl status snap.certbot.renew.timer
```

### **Self-signed Certificates**

For testing or internal use:

```bash
# Certificate generation
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/nginx/server.key \
    -out /etc/ssl/nginx/server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$DOMAIN_NAME"
```

## 🌐 Nginx Configuration

### **Reverse Proxy Setup**

The installer creates a production-ready Nginx configuration:

```nginx
# Upstream configuration
upstream odoo {
  server 127.0.0.1:8069;
}
upstream odoochat {
  server 127.0.0.1:8072;
}

# HTTP to HTTPS redirect
server {
  listen 80;
  server_name example.com;
  rewrite ^(.*) https://$host$1 permanent;
}

# HTTPS server block
server {
  listen 443 ssl;
  server_name example.com;
  
  # SSL configuration
  ssl_certificate /path/to/certificate;
  ssl_certificate_key /path/to/private/key;
  ssl_protocols TLSv1.2 TLSv1.3;
  
  # Proxy configuration
  location / {
    proxy_pass http://odoo;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
  }
  
  # WebSocket support
  location /websocket {
    proxy_pass http://odoochat;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
  }
}
```

### **Security Headers**

```nginx
# Security enhancements
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
proxy_cookie_flags session_id samesite=lax secure;
```

## 🔧 Troubleshooting

### **Common Issues**

#### **DNS Resolution Problems**
```bash
# Check DNS configuration
dig +short your-domain.com

# Verify server IP
curl -s ifconfig.me

# Test domain resolution
nslookup your-domain.com
```

#### **Live Chat / Notifications Disconnect (websocket 502)**
Nginx sends `/websocket` to port 8072, which Odoo only opens when `workers` is greater than 0:
```bash
grep -E '^workers' /etc/odoo/odoo.conf   # must be > 0 behind Nginx
ss -ltnp | grep 8072                     # Odoo should be listening here
```

#### **Odoo 14.0 on Ubuntu 24.04**
Odoo 14.0 pins `gevent`, `greenlet` and `Pillow` versions that do not build on Python 3.12, so its requirements fail to install. Use Ubuntu 22.04 with `odoo_installer.sh` for Odoo 14.0.

#### **Service Status Checks**
```bash
# Check Odoo service
systemctl status odoo
journalctl -u odoo -f

# Check PostgreSQL
systemctl status postgresql
sudo -u postgres psql -l

# Check Nginx (if installed)
systemctl status nginx
nginx -t
```

#### **Log File Locations**
```bash
# Installation logs
/tmp/odoo_install_YYYYMMDD_HHMMSS.log

# Odoo application logs
/var/log/odoo/odoo-server.log

# Nginx logs (if installed)
/var/log/nginx/odoo.access.log
/var/log/nginx/odoo.error.log

# System logs
journalctl -u odoo
journalctl -u nginx
```

### **Port Configuration**

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Odoo | 8069 | HTTP | Web interface |
| Odoo | 8072 | HTTP | WebSocket/Chat |
| Nginx | 80 | HTTP | HTTP redirect |
| Nginx | 443 | HTTPS | Secure web access |
| PostgreSQL | 5432 | TCP | Database |
| Webmin | 10000 | HTTPS | Server administration (24.04, optional) |

### **File Permissions**

```bash
# Odoo directories
/odoo/odoo/          - odoo:odoo (755)
/odoo/enterprise/    - odoo:odoo (755, Enterprise only)
/odoo/python/        - odoo:odoo (755, Python virtual environment, 24.04 only)
/etc/odoo/           - odoo:odoo (755)
/var/log/odoo/       - odoo:odoo (755)

# Configuration files
/etc/odoo/odoo.conf  - odoo:odoo (640)

# SSL certificates
/etc/ssl/nginx/      - root:root (644/600)
```

## 🧪 Testing the Installation

### **Basic Functionality Test**
```bash
# Test Odoo web interface
curl -I http://localhost:8069

# Test with Nginx (if installed)
curl -I https://your-domain.com

# Check database connectivity
sudo -u odoo psql -h localhost -p 5432 -U odoo -l
```

### **SSL Certificate Validation**
```bash
# Check certificate details
openssl x509 -in /path/to/certificate -text -noout

# Test SSL connection
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

## 📊 Performance Optimization

### **Recommended System Tuning**

#### **PostgreSQL Configuration**
```sql
-- /etc/postgresql/16/main/postgresql.conf
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
```

#### **Nginx Optimization**
```nginx
# /etc/nginx/nginx.conf
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
client_max_body_size 100M;
```

#### **Odoo Configuration Tuning**
```ini
# /etc/odoo/odoo.conf
workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200
```

## 🔄 Backup and Maintenance

### **Database Backup**
```bash
# Create database backup
sudo -u odoo pg_dump -h localhost -p 5432 -U odoo database_name > backup.sql

# Restore database
sudo -u odoo psql -h localhost -p 5432 -U odoo -d database_name < backup.sql
```

### **File System Backup**
```bash
# Backup Odoo files
tar -czf odoo_backup.tar.gz /odoo/odoo /etc/odoo /var/log/odoo

# Backup SSL certificates
tar -czf ssl_backup.tar.gz /etc/ssl/nginx /etc/letsencrypt
```

### **Update Procedures**
```bash
# Pull the latest fixes for the installed Odoo version
cd /odoo/odoo
sudo -u odoo git pull
# Ubuntu 24.04: refresh Python requirements in the virtual environment
sudo -u odoo /odoo/python/bin/pip install -r /odoo/odoo/requirements.txt
sudo systemctl restart odoo

# Moving to a new major version (e.g. 19.0 -> 20.0) needs a database migration
# through Odoo's upgrade service (https://upgrade.odoo.com); checking out a new
# branch on an existing database is not enough

# Update system packages
sudo apt update && sudo apt upgrade

# Update SSL certificates
sudo certbot renew
```

## 🤝 Contributing

We welcome contributions to improve the Enhanced Odoo Installer! Here's how you can help:

### **Development Setup**
```bash
# Clone the repository
git clone https://github.com/mah007/OdooScript.git
cd OdooScript

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes, check the syntax, then test on a fresh VM (never on your workstation)
bash -n odoo_installer_24.sh
shellcheck odoo_installer_24.sh

# Commit and push
git commit -m "Add your feature description"
git push origin feature/your-feature-name
```

### **Testing Guidelines**
- Test on clean Ubuntu 24.04 and 22.04 installations
- Verify both domain and IP-based installations
- Test SSL certificate generation (both Let's Encrypt and self-signed)
- Validate the supported Odoo versions (15.0-20.0 on 24.04, 14.0-18.0 on 22.04)
- Test both Community and Enterprise editions on 24.04
- Check error handling and recovery scenarios

### **Code Style**
- Use consistent bash scripting practices
- Add comments for complex logic
- Follow the existing function naming convention
- Include proper error handling
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Odoo](https://www.odoo.com/) for the amazing ERP platform
- [Nginx](https://nginx.org/) for the high-performance web server
- [Let's Encrypt](https://letsencrypt.org/) for free SSL certificates
- [PostgreSQL](https://www.postgresql.org/) for the robust database system
- The open-source community for continuous inspiration

## 📞 Support

- **Documentation**: [GitHub Wiki](https://github.com/mah007/OdooScript/wiki)
- **Issues**: [GitHub Issues](https://github.com/mah007/OdooScript/issues)
- **Discussions**: [GitHub Discussions](https://github.com/mah007/OdooScript/discussions)

---

<div align="center">

**Made with ❤️ for the Odoo community By Mahmoud Abdel Latif**


[Website](https://mah007.net) • [Documentation](https://github.com/mah007/OdooScript/wiki) • [Issues](https://github.com/mah007/OdooScript/issues)

</div>



# OdooScript
Odoo dependence installation script for Ubuntu 14.04 , 15.04 ,16.04 ,20.04 , 22.04 ,*24.04(universal)  
make your envirument ready for all kind of odoo with pycharm IDE
after run the script u have to download odoo manully 

ssh-keygen -t ed25519 -C "your_email@example.com"

### Copy this script and run it on your terminal 

./odoo-bin -w a -s -c  ../odoo.conf --stop-after-init

./odoo-bin -w a -s -c  /etc/odoo/odoo.conf --stop-after-init

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
