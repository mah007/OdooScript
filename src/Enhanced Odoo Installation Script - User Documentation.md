# Enhanced Odoo Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20LTS-orange.svg)](https://ubuntu.com/)
[![Odoo](https://img.shields.io/badge/Odoo-14.0%20to%2018.0-purple.svg)](https://www.odoo.com/)
[![Nginx](https://img.shields.io/badge/Nginx-Latest-green.svg)](https://nginx.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)

> **Professional Odoo installation script with domain configuration, official Nginx, SSL certificates, and dynamic configuration generation for Ubuntu 22.04**

## 🚀 Quick Start

```bash
# Download the installer
wget https://raw.githubusercontent.com/mah007/OdooScript/refs/heads/16.0/odoo_installer.sh
# Make it executable
chmod +x odoo_installer.sh

# Run the installer
sudo ./odoo_installer.sh
```

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
- Native Odoo configuration generation using `odoo-bin`
- Clean configuration without forced master passwords
- Automatic proxy mode detection for Nginx setups
- Secure file permissions and ownership

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
- Ubuntu 22.04 LTS (Jammy Jellyfish)
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
- Open ports: 80 (HTTP), 443 (HTTPS), 8069 (Odoo direct)

## 🔄 Installation Process

The installer follows an 8-step automated process:

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
- Python 3.11 packages and libraries
- System development tools
- Node.js and npm packages
- Odoo-specific dependencies

### **Step 5: Wkhtmltopdf Installation**
- PDF generation library installation
- Architecture detection (x64/x32)
- Version verification
- Integration testing

### **Step 6: Odoo Installation**
- Source code download from official repository
- Python requirements installation
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
- Odoo 14.0 (LTS)
- Odoo 15.0
- Odoo 16.0
- Odoo 17.0
- Odoo 18.0 (Latest)

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
```ini
[options]
; Basic Odoo configuration
db_host = localhost
db_port = 5432
db_user = odoo
db_password = False
addons_path = /odoo/odoo/addons
logfile = /var/log/odoo/odoo-server.log
log_level = info
; Proxy mode configuration (when Nginx is installed)
proxy_mode = True
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

### **File Permissions**

```bash
# Odoo directories
/odoo/odoo/          - odoo:odoo (755)
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
# Update Odoo to newer version
cd /odoo/odoo
git fetch origin
git checkout 17.0  # or desired version
sudo systemctl restart odoo

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

# Make your changes and test
./odoo_installer.sh

# Commit and push
git commit -m "Add your feature description"
git push origin feature/your-feature-name
```

### **Testing Guidelines**
- Test on clean Ubuntu 22.04 installations
- Verify both domain and IP-based installations
- Test SSL certificate generation (both Let's Encrypt and self-signed)
- Validate all Odoo versions (14.0-18.0)
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

- **Documentation**: [GitHub Wiki](https://github.com/yourusername/OdooScript/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/OdooScript/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/OdooScript/discussions)

---

<div align="center">

**Made with ❤️ for the Odoo community By Mahmoud Abdel Latif**


[Website](https://mah007.net) • [Documentation](https://github.com/mah007/OdooScript/wiki) • [Issues](https://github.com/mah007/OdooScript/issues)

</div>

