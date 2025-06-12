# Technical Documentation

## Script Architecture

### Overview
The Enhanced Odoo Installer is a comprehensive bash script designed to automate the installation and configuration of Odoo ERP system on Ubuntu 22.04 LTS. The script follows enterprise-grade practices with robust error handling, comprehensive logging, and modular architecture.

### Core Design Principles

1. **Modularity**: Each installation step is encapsulated in dedicated functions
2. **Error Resilience**: Comprehensive error handling with graceful degradation
3. **User Experience**: Interactive prompts with clear feedback and progress tracking
4. **Security**: Secure defaults, proper permissions, and modern cryptographic standards
5. **Flexibility**: Support for multiple installation scenarios and configurations

## Script Structure

### Global Configuration
```bash
# Script metadata
SCRIPT_VERSION="2.1-COMPLETE"
SCRIPT_NAME="Enhanced Odoo Installer with Domain & SSL Support"
LOG_FILE="/tmp/odoo_install_$(date +%Y%m%d_%H%M%S).log"

# Installation parameters
OE_USER="odoo"
TOTAL_STEPS=8
INSTALL_WKHTMLTOPDF="True"
IS_ENTERPRISE="True"

# Domain and SSL management
DOMAIN_NAME=""
HAS_DOMAIN="false"
INSTALL_NGINX="false"
SSL_TYPE=""  # "self-signed" or "letsencrypt"
SERVER_IP=""
```

### Utility Functions

#### Logging System
```bash
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR")   echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "INFO")    echo -e "${GREEN}[INFO]${NC} $message" ;;
        "DEBUG")   echo -e "${CYAN}[DEBUG]${NC} $message" ;;
    esac
}
```

#### Progress Tracking
```bash
show_progress_bar() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${BLUE}["
    printf "%*s" $completed | tr ' ' '='
    printf "%*s" $remaining | tr ' ' '-'
    printf "] %d%% (%d/%d)${NC}" $percentage $current $total
}
```

#### Command Execution
```bash
execute_simple() {
    local command="$1"
    local description="$2"
    
    log_message "DEBUG" "Executing: $command"
    echo -e "${CYAN}$description...${NC}"
    
    if eval "$command" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC} $description"
        log_message "INFO" "Successfully completed: $description"
        return 0
    else
        local exit_code=$?
        echo -e "${RED}✗${NC} $description"
        log_message "ERROR" "Failed to execute: $description (Exit code: $exit_code)"
        return $exit_code
    fi
}
```

## Installation Steps

### Step 1: Pre-flight Checks
**Function**: `step_preflight_checks()`

**Purpose**: Validates system requirements and configuration before installation

**Operations**:
- Root privilege verification
- Ubuntu version compatibility check
- Disk space validation (minimum 10GB)
- Memory check (minimum 2GB recommended)
- Internet connectivity test
- Odoo version validation

**Error Handling**: Exits with error code 1 if critical requirements are not met

### Step 2: System Preparation
**Function**: `step_system_preparation()`

**Purpose**: Prepares the system environment for Odoo installation

**Operations**:
```bash
# User and group management
groupadd -f $OE_USER
useradd --create-home -d /home/$OE_USER --shell /bin/bash -g $OE_USER $OE_USER
usermod -aG sudo $OE_USER

# System updates
apt-get update
apt-get upgrade -y
apt install -y zip gdebi net-tools curl wget gnupg2 software-properties-common

# Locale configuration
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
dpkg-reconfigure -f noninteractive locales
```

### Step 3: Database Setup
**Function**: `step_database_setup()`

**Purpose**: Installs and configures PostgreSQL database

**Operations**:
```bash
# Add PostgreSQL official repository
sh -c 'echo "deb [arch=amd64] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Install PostgreSQL 16
apt-get update
apt-get install -y postgresql-16 postgresql-server-dev-16

# Create Odoo database user
su - postgres -c "createuser -s $OE_USER"

# Service management
systemctl enable postgresql
systemctl start postgresql
```

### Step 4: Dependencies Installation
**Function**: `step_dependencies_installation()`

**Purpose**: Installs system and Python dependencies required by Odoo

**System Packages**:
```bash
system_packages=(
    "git" "python3-pip" "build-essential" "wget" "python3-dev" 
    "python3-venv" "python3-wheel" "libfreetype6-dev" "libxml2-dev" 
    "libzip-dev" "libldap2-dev" "libsasl2-dev" "python3-setuptools" 
    "node-less" "libjpeg-dev" "zlib1g-dev" "libpq-dev" "libtiff5-dev" 
    "libjpeg8-dev" "libopenjp2-7-dev" "liblcms2-dev" "libwebp-dev" 
    "libharfbuzz-dev" "libfribidi-dev" "libxcb1-dev" "libwww-perl"
    "gsfonts" "libcairo2-dev" "python3-cairo"
)
```

**Node.js Installation**:
```bash
# Add Node.js 20.x repository
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main' | tee /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs
```

### Step 5: Wkhtmltopdf Installation
**Function**: `step_wkhtmltopdf_installation()`

**Purpose**: Installs PDF generation library for Odoo reports

**Architecture Detection**:
```bash
if [ "$(getconf LONG_BIT)" == "64" ]; then
    wkhtml_url="$WKHTML_X64"
else
    wkhtml_url="$WKHTML_X32"
fi
```

**Installation Process**:
```bash
wget -O /tmp/$wkhtml_file $wkhtml_url
gdebi --non-interactive /tmp/$wkhtml_file
rm -f /tmp/$wkhtml_file
```

### Step 6: Odoo Installation
**Function**: `step_odoo_installation()`

**Purpose**: Downloads and configures Odoo source code

**Directory Structure**:
```bash
mkdir -p /odoo
mkdir -p /etc/odoo
mkdir -p /var/log/odoo
touch /var/log/odoo/odoo-server.log
```

**Source Code Download**:
```bash
cd /odoo
git clone --depth 1 --branch $OE_BRANCH https://www.github.com/odoo/odoo
chown -R $OE_USER:$OE_USER /odoo
```

**Python Requirements**:
```bash
su - $OE_USER -s /bin/bash -c "pip3 install -r https://raw.githubusercontent.com/odoo/odoo/$OE_BRANCH/requirements.txt --user"
su - $OE_USER -s /bin/bash -c "pip3 install phonenumbers --user"
```

### Step 7: Service Configuration
**Function**: `step_service_configuration()`

**Purpose**: Configures Odoo as a system service and sets up Nginx if requested

**Systemd Service**:
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

**Nginx Configuration** (if selected):
- Official Nginx installation from nginx.org
- SSL certificate generation (Let's Encrypt or self-signed)
- Reverse proxy configuration with WebSocket support

### Step 8: Final Setup
**Function**: `step_final_setup()`

**Purpose**: Validates installation and generates reports

**Validation Tests**:
- Service status verification
- Network connectivity tests
- SSL certificate validation
- File permission checks

## Domain and SSL Management

### Domain Configuration Flow
```bash
configure_domain() {
    # Get server IP
    get_server_ip()
    
    # Domain input and validation
    if [ "$HAS_DOMAIN" = "true" ]; then
        # Domain format validation
        # DNS verification
        verify_domain_dns()
    fi
}
```

### DNS Verification
```bash
verify_domain_dns() {
    local domain_ip=$(dig +short "$DOMAIN_NAME" 2>/dev/null | tail -n1)
    
    if [ "$domain_ip" = "$SERVER_IP" ]; then
        echo -e "${GREEN}✓ Domain DNS is correctly configured${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Domain points to $domain_ip but server IP is $SERVER_IP${NC}"
        # User confirmation for continuation
    fi
}
```

### SSL Certificate Management

#### Let's Encrypt Integration
```bash
install_letsencrypt_ssl() {
    # Install snapd and certbot
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
    
    # Create temporary Nginx configuration
    create_temporary_nginx_config()
    
    # Obtain certificate
    certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME
    
    # Test automatic renewal
    certbot renew --dry-run
}
```

#### Self-signed Certificate Generation
```bash
generate_self_signed_ssl() {
    mkdir -p /etc/ssl/nginx
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/nginx/server.key \
        -out /etc/ssl/nginx/server.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$DOMAIN_NAME"
    
    chmod 600 /etc/ssl/nginx/server.key
    chmod 644 /etc/ssl/nginx/server.crt
}
```

## Nginx Configuration

### Official Nginx Installation
```bash
install_official_nginx() {
    # Remove existing installations
    apt-get remove -y nginx nginx-common nginx-core
    
    # Add official repository
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
    echo 'deb https://nginx.org/packages/ubuntu/ jammy nginx' > /etc/apt/sources.list.d/nginx.list
    
    # Set repository priority
    cat > /etc/apt/preferences.d/99nginx << EOF
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
EOF
    
    # Install and configure
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
}
```

### Reverse Proxy Configuration
```nginx
upstream odoo {
  server 127.0.0.1:8069;
}
upstream odoochat {
  server 127.0.0.1:8072;
}

map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}

server {
  listen 443 ssl;
  server_name $DOMAIN_NAME;
  
  # SSL configuration
  ssl_certificate $ssl_cert_path;
  ssl_certificate_key $ssl_key_path;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...;
  
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

## Dynamic Configuration Generation

### Odoo Configuration Process
```bash
generate_odoo_config() {
    # Create basic configuration
    cat > /etc/odoo/odoo.conf << EOF
[options]
; Basic Odoo configuration
db_host = localhost
db_port = 5432
db_user = $OE_USER
db_password = False
addons_path = /odoo/odoo/addons
logfile = /var/log/odoo/odoo-server.log
log_level = info
EOF
    
    # Set permissions
    chown $OE_USER:$OE_USER /etc/odoo/odoo.conf
    chmod 640 /etc/odoo/odoo.conf
    
    # Generate configuration using Odoo
    su - $OE_USER -s /bin/bash -c 'cd /odoo/odoo && ./odoo-bin -s -c /etc/odoo/odoo.conf --stop-after-init'
    
    # Add proxy mode if Nginx is installed
    if [ "$INSTALL_NGINX" = "true" ]; then
        echo "proxy_mode = True" >> /etc/odoo/odoo.conf
    fi
}
```

## Error Handling and Logging

### Error Handling Strategy
1. **Graceful Degradation**: Continue installation when non-critical components fail
2. **User Notification**: Clear error messages with suggested solutions
3. **Detailed Logging**: Comprehensive logs for troubleshooting
4. **Recovery Options**: Ability to resume installation after fixing issues

### Logging Levels
- **DEBUG**: Detailed execution information
- **INFO**: General information about progress
- **WARNING**: Non-critical issues that don't stop installation
- **ERROR**: Critical issues that require attention

### Log File Structure
```
[2024-06-12 09:30:15] [INFO] Starting Enhanced Odoo Installer v2.1-COMPLETE
[2024-06-12 09:30:16] [DEBUG] Executing: apt-get update
[2024-06-12 09:30:45] [INFO] Successfully completed: Updating package lists
[2024-06-12 09:30:46] [WARNING] Failed to install libxml2-dev, continuing
[2024-06-12 09:35:22] [INFO] Installation completed successfully in 5m 7s
```

## Security Considerations

### File Permissions
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

### User Management
- Dedicated `odoo` user for running services
- Minimal privileges principle
- Sudo access only when necessary

### Network Security
- Modern TLS configuration (TLS 1.2/1.3)
- Security headers implementation
- Secure cookie flags
- HSTS enforcement

## Performance Considerations

### Resource Management
- Efficient package installation with error recovery
- Minimal system impact during installation
- Optimized configuration for production use

### Scalability
- Support for multi-worker configuration
- Database connection pooling
- Nginx load balancing preparation

## Maintenance and Updates

### Update Procedures
```bash
# Odoo version update
cd /odoo/odoo
git fetch origin
git checkout 17.0
systemctl restart odoo

# SSL certificate renewal
certbot renew

# System package updates
apt update && apt upgrade
```

### Backup Recommendations
```bash
# Database backup
pg_dump -h localhost -p 5432 -U odoo database_name > backup.sql

# File system backup
tar -czf odoo_backup.tar.gz /odoo/odoo /etc/odoo /var/log/odoo

# SSL certificate backup
tar -czf ssl_backup.tar.gz /etc/ssl/nginx /etc/letsencrypt
```

## Testing and Validation

### Automated Tests
- Service status verification
- Network connectivity tests
- SSL certificate validation
- Database connection testing
- File permission verification

### Manual Testing Procedures
```bash
# Test Odoo web interface
curl -I http://localhost:8069

# Test SSL configuration
openssl s_client -connect domain.com:443 -servername domain.com

# Test database connectivity
sudo -u odoo psql -h localhost -p 5432 -U odoo -l
```

## Troubleshooting Guide

### Common Issues and Solutions

#### DNS Resolution Problems
```bash
# Check DNS configuration
dig +short your-domain.com
nslookup your-domain.com

# Verify server IP
curl -s ifconfig.me
```

#### Service Startup Issues
```bash
# Check service status
systemctl status odoo
journalctl -u odoo -f

# Check configuration
sudo -u odoo /odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf --test-enable
```

#### SSL Certificate Issues
```bash
# Test certificate
openssl x509 -in /path/to/certificate -text -noout

# Renew Let's Encrypt certificate
certbot renew --force-renewal
```

### Log Analysis
- Installation logs: `/tmp/odoo_install_YYYYMMDD_HHMMSS.log`
- Odoo logs: `/var/log/odoo/odoo-server.log`
- Nginx logs: `/var/log/nginx/odoo.error.log`
- System logs: `journalctl -u odoo`

## Future Enhancements

### Planned Features
- Multi-server deployment support
- Docker containerization option
- Automated backup configuration
- Performance monitoring integration
- Custom addon management

### Extensibility
The script is designed to be easily extensible with:
- Plugin architecture for additional features
- Configuration file customization
- Custom installation hooks
- Third-party integration points

