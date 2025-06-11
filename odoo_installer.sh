#!/bin/bash

# Enhanced Odoo Installation Script for Ubuntu 22.04 - Modified Version
# Version: 2.1
# Author: Mahmoud Abdel Latif
# Description: Interactive Odoo installation with enhanced Nginx, SSL, and domain handling

# Script configuration
SCRIPT_VERSION="2.1"
SCRIPT_NAME="Enhanced Odoo Installer with Advanced Nginx"
LOG_FILE="/tmp/odoo_install_$(date +%Y%m%d_%H%M%S).log"
CONFIG_FILE="/tmp/odoo_install_config.conf"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Progress tracking
TOTAL_STEPS=8
CURRENT_STEP=0
STEP_PROGRESS=0

# Installation configuration
OE_USER="odoo"
OE_BRANCH=""
INSTALL_WKHTMLTOPDF="True"
IS_ENTERPRISE="True"
WKHTML_X64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb"
WKHTML_X32="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb"

# New variables for domain and SSL management
DOMAIN_NAME=""
HAS_DOMAIN="false"
INSTALL_NGINX="false"
SSL_TYPE=""  # "self-signed" or "letsencrypt"
SERVER_IP=""

# Trap for cleanup on exit
trap cleanup_on_exit EXIT INT TERM

#==============================================================================
# UTILITY FUNCTIONS
#==============================================================================

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "DEBUG")
            echo -e "${CYAN}[DEBUG]${NC} $message"
            ;;
    esac
}

# Progress bar function
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

# Spinner animation
show_spinner() {
    local pid=$1
    local message="$2"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${CYAN}${spin:$i:1} %s${NC}" "$message"
        sleep 0.1
    done
    printf "\r${GREEN}✓${NC} %s\n" "$message"
}

# Enhanced billboard display
display_billboard() {
    local message="$1"
    local width=80
    local padding=$(( (width - ${#message}) / 2 ))
    
    echo
    echo -e "${PURPLE}${BOLD}$(printf '%*s' $width | tr ' ' '=')"
    echo -e "$(printf '%*s' $padding)${WHITE}$message${PURPLE}"
    echo -e "$(printf '%*s' $width | tr ' ' '=')${NC}"
    echo
}

# Step header
show_step_header() {
    local step_num="$1"
    local step_name="$2"
    local step_desc="$3"
    
    CURRENT_STEP=$step_num
    echo
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${WHITE}Step $step_num/$TOTAL_STEPS: $step_name${NC}"
    echo -e "${CYAN}$step_desc${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    show_progress_bar $step_num $TOTAL_STEPS
    echo
    log_message "INFO" "Starting Step $step_num: $step_name"
}

# Execute command with error handling
execute_command() {
    local command="$1"
    local description="$2"
    local show_output="${3:-false}"
    
    log_message "DEBUG" "Executing: $command"
    
    if [ "$show_output" = "true" ]; then
        echo -e "${YELLOW}Executing: $description${NC}"
        eval "$command" 2>&1 | tee -a "$LOG_FILE"
        local exit_code=${PIPESTATUS[0]}
    else
        eval "$command" >> "$LOG_FILE" 2>&1 &
        local pid=$!
        show_spinner $pid "$description"
        wait $pid
        local exit_code=$?
    fi
    
    if [ $exit_code -eq 0 ]; then
        log_message "INFO" "Successfully completed: $description"
        return 0
    else
        log_message "ERROR" "Failed to execute: $description (Exit code: $exit_code)"
        return $exit_code
    fi
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo
        echo -e "${RED}${BOLD}Installation interrupted or failed!${NC}"
        echo -e "${YELLOW}Check the log file for details: $LOG_FILE${NC}"
        echo -e "${YELLOW}You can resume the installation by running this script again.${NC}"
    fi
}

#==============================================================================
# DOMAIN AND NETWORK FUNCTIONS
#==============================================================================

# Get server IP address
get_server_ip() {
    # Try multiple methods to get the public IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
    
    if [ -z "$SERVER_IP" ]; then
        # Fallback to local IP
        SERVER_IP=$(hostname -I | awk '{print $1}')
    fi
    
    log_message "INFO" "Detected server IP: $SERVER_IP"
}

# Domain configuration function
configure_domain() {
    clear
    display_billboard "Domain Configuration"
    
    echo -e "${BOLD}${WHITE}Domain Setup for Odoo Installation${NC}"
    echo
    echo -e "${CYAN}This step will configure your domain settings for Odoo.${NC}"
    echo -e "${CYAN}If you have a domain, we can set up SSL certificates automatically.${NC}"
    echo
    
    # Get server IP
    get_server_ip
    echo -e "${YELLOW}Your server IP address: ${BOLD}$SERVER_IP${NC}"
    echo
    
    while true; do
        read -rp "$(echo -e ${BOLD}${WHITE}Do you have a domain name pointing to this server? [y/N]: ${NC})" has_domain_input
        case "$has_domain_input" in
            [Yy]|[Yy][Ee][Ss])
                HAS_DOMAIN="true"
                break
                ;;
            [Nn]|[Nn][Oo]|"")
                HAS_DOMAIN="false"
                break
                ;;
            *)
                echo -e "${RED}Please answer yes (y) or no (n).${NC}"
                ;;
        esac
    done
    
    if [ "$HAS_DOMAIN" = "true" ]; then
        while true; do
            read -rp "$(echo -e ${BOLD}${WHITE}Enter your domain name (e.g., odoo.mycompany.com): ${NC})" domain_input
            
            if [ -n "$domain_input" ]; then
                # Basic domain validation
                if [[ "$domain_input" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                    DOMAIN_NAME="$domain_input"
                    echo -e "${GREEN}Domain set to: $DOMAIN_NAME${NC}"
                    
                    # Verify domain points to this server
                    verify_domain_dns
                    break
                else
                    echo -e "${RED}Invalid domain format. Please enter a valid domain name.${NC}"
                fi
            else
                echo -e "${RED}Domain name cannot be empty.${NC}"
            fi
        done
    else
        echo -e "${YELLOW}No domain configured. Will use IP address access only.${NC}"
        DOMAIN_NAME="$SERVER_IP"
    fi
    
    log_message "INFO" "Domain configuration: HAS_DOMAIN=$HAS_DOMAIN, DOMAIN_NAME=$DOMAIN_NAME"
}

# Verify domain DNS
verify_domain_dns() {
    echo -e "${CYAN}Verifying domain DNS configuration...${NC}"
    
    local domain_ip=$(dig +short "$DOMAIN_NAME" 2>/dev/null | tail -n1)
    
    if [ -n "$domain_ip" ]; then
        if [ "$domain_ip" = "$SERVER_IP" ]; then
            echo -e "${GREEN}✓ Domain DNS is correctly configured${NC}"
            log_message "INFO" "Domain DNS verification successful: $DOMAIN_NAME -> $domain_ip"
        else
            echo -e "${YELLOW}⚠ Warning: Domain points to $domain_ip but server IP is $SERVER_IP${NC}"
            echo -e "${YELLOW}  SSL certificate generation may fail if DNS is not properly configured.${NC}"
            log_message "WARNING" "Domain DNS mismatch: $DOMAIN_NAME -> $domain_ip (expected: $SERVER_IP)"
            
            read -rp "$(echo -e ${BOLD}${WHITE}Continue anyway? [y/N]: ${NC})" continue_anyway
            if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
                echo -e "${RED}Please configure your domain DNS to point to $SERVER_IP and try again.${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${YELLOW}⚠ Warning: Could not resolve domain $DOMAIN_NAME${NC}"
        echo -e "${YELLOW}  Please ensure your domain DNS is properly configured.${NC}"
        log_message "WARNING" "Could not resolve domain: $DOMAIN_NAME"
        
        read -rp "$(echo -e ${BOLD}${WHITE}Continue anyway? [y/N]: ${NC})" continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Please configure your domain DNS and try again.${NC}"
            exit 1
        fi
    fi
}

# Nginx installation preference
configure_nginx_installation() {
    clear
    display_billboard "Web Server Configuration"
    
    echo -e "${BOLD}${WHITE}Nginx Reverse Proxy Setup${NC}"
    echo
    echo -e "${CYAN}Nginx will act as a reverse proxy for Odoo, providing:${NC}"
    echo -e "  ${GREEN}•${NC} SSL/TLS encryption"
    echo -e "  ${GREEN}•${NC} Better performance and caching"
    echo -e "  ${GREEN}•${NC} Load balancing capabilities"
    echo -e "  ${GREEN}•${NC} Security enhancements"
    echo
    
    while true; do
        read -rp "$(echo -e ${BOLD}${WHITE}Do you want to install and configure Nginx? [Y/n]: ${NC})" install_nginx_input
        case "$install_nginx_input" in
            [Yy]|[Yy][Ee][Ss]|"")
                INSTALL_NGINX="true"
                break
                ;;
            [Nn]|[Nn][Oo])
                INSTALL_NGINX="false"
                echo -e "${YELLOW}Nginx installation skipped. Odoo will be accessible directly on port 8069.${NC}"
                break
                ;;
            *)
                echo -e "${RED}Please answer yes (y) or no (n).${NC}"
                ;;
        esac
    done
    
    if [ "$INSTALL_NGINX" = "true" ]; then
        configure_ssl_type
    fi
    
    log_message "INFO" "Nginx installation preference: $INSTALL_NGINX"
}

# SSL certificate type configuration
configure_ssl_type() {
    echo
    echo -e "${BOLD}${WHITE}SSL Certificate Configuration${NC}"
    echo
    
    if [ "$HAS_DOMAIN" = "true" ]; then
        echo -e "${CYAN}Choose SSL certificate type:${NC}"
        echo -e "  ${YELLOW}1)${NC} Let's Encrypt (Free, automatic renewal) ${GREEN}[Recommended]${NC}"
        echo -e "  ${YELLOW}2)${NC} Self-signed certificate (For testing/internal use)"
        echo
        
        while true; do
            read -rp "$(echo -e ${BOLD}${WHITE}Enter your choice [1-2]: ${NC})" ssl_choice
            case "$ssl_choice" in
                1)
                    SSL_TYPE="letsencrypt"
                    echo -e "${GREEN}Selected: Let's Encrypt SSL certificate${NC}"
                    break
                    ;;
                2)
                    SSL_TYPE="self-signed"
                    echo -e "${YELLOW}Selected: Self-signed SSL certificate${NC}"
                    break
                    ;;
                *)
                    echo -e "${RED}Invalid choice. Please select 1 or 2.${NC}"
                    ;;
            esac
        done
    else
        SSL_TYPE="self-signed"
        echo -e "${YELLOW}No domain configured. Will use self-signed SSL certificate.${NC}"
    fi
    
    log_message "INFO" "SSL certificate type: $SSL_TYPE"
}

#==============================================================================
# VALIDATION FUNCTIONS
#==============================================================================

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "ERROR" "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check system requirements
check_system_requirements() {
    local errors=0
    
    # Check Ubuntu version
    if ! lsb_release -d | grep -q "Ubuntu 22.04"; then
        log_message "WARNING" "This script is optimized for Ubuntu 22.04. Current version: $(lsb_release -d | cut -f2)"
    fi
    
    # Check available disk space (minimum 10GB)
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=10485760  # 10GB in KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        log_message "ERROR" "Insufficient disk space. Required: 10GB, Available: $((available_space/1024/1024))GB"
        errors=$((errors + 1))
    fi
    
    # Check memory (minimum 2GB)
    local total_memory=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_memory" -lt 2048 ]; then
        log_message "WARNING" "Low memory detected. Recommended: 2GB+, Available: ${total_memory}MB"
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        log_message "ERROR" "No internet connection detected"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Validate Odoo version selection
validate_odoo_version() {
    case "$OE_BRANCH" in
        "14.0"|"15.0"|"16.0"|"17.0"|"18.0")
            return 0
            ;;
        *)
            log_message "ERROR" "Invalid Odoo version: $OE_BRANCH"
            return 1
            ;;
    esac
}

#==============================================================================
# INTERACTIVE FUNCTIONS
#==============================================================================

# Interactive main menu
show_main_menu() {
    while true; do
        clear
        display_billboard "$SCRIPT_NAME v$SCRIPT_VERSION"
        
        echo -e "${BOLD}${WHITE}Welcome to the Enhanced Odoo Installation Script!${NC}"
        echo
        echo -e "${CYAN}This script will install Odoo on Ubuntu 22.04 with the following features:${NC}"
        echo -e "  ${GREEN}•${NC} Interactive installation process"
        echo -e "  ${GREEN}•${NC} Official Nginx installation with SSL support"
        echo -e "  ${GREEN}•${NC} Domain configuration and Let's Encrypt integration"
        echo -e "  ${GREEN}•${NC} Dynamic Odoo configuration generation"
        echo -e "  ${GREEN}•${NC} Comprehensive error handling"
        echo
        echo -e "${BOLD}${WHITE}Please select an option:${NC}"
        echo -e "  ${YELLOW}1)${NC} Start Full Installation"
        echo -e "  ${YELLOW}2)${NC} Custom Installation"
        echo -e "  ${YELLOW}3)${NC} System Check Only"
        echo -e "  ${YELLOW}4)${NC} View Installation Log"
        echo -e "  ${YELLOW}5)${NC} Help & Documentation"
        echo -e "  ${YELLOW}6)${NC} Exit"
        echo
        
        read -rp "$(echo -e ${BOLD}${WHITE}Enter your choice [1-6]: ${NC})" choice
        
        case "$choice" in
            1)
                select_odoo_version
                if [ $? -eq 0 ]; then
                    configure_domain
                    configure_nginx_installation
                    confirm_installation
                    if [ $? -eq 0 ]; then
                        return 0
                    fi
                fi
                ;;
            2)
                custom_installation_menu
                ;;
            3)
                system_check_only
                ;;
            4)
                view_log
                ;;
            5)
                show_help
                ;;
            6)
                echo -e "${GREEN}Thank you for using $SCRIPT_NAME!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please select 1-6.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Odoo version selection with enhanced UI
select_odoo_version() {
    while true; do
        clear
        display_billboard "Odoo Version Selection"
        
        echo -e "${BOLD}${WHITE}Please select the Odoo version to install:${NC}"
        echo
        echo -e "  ${YELLOW}1)${NC} Odoo 14.0 ${CYAN}(LTS - Long Term Support)${NC}"
        echo -e "  ${YELLOW}2)${NC} Odoo 15.0 ${CYAN}(Stable)${NC}"
        echo -e "  ${YELLOW}3)${NC} Odoo 16.0 ${CYAN}(Stable)${NC}"
        echo -e "  ${YELLOW}4)${NC} Odoo 17.0 ${CYAN}(Latest Stable)${NC}"
        echo -e "  ${YELLOW}5)${NC} Odoo 18.0 ${CYAN}(Latest - May have issues)${NC}"
        echo -e "  ${YELLOW}6)${NC} Back to Main Menu"
        echo
        
        read -rp "$(echo -e ${BOLD}${WHITE}Enter your choice [1-6]: ${NC})" choice
        
        case "$choice" in
            1) OE_BRANCH="14.0"; break;;
            2) OE_BRANCH="15.0"; break;;
            3) OE_BRANCH="16.0"; break;;
            4) OE_BRANCH="17.0"; break;;
            5) OE_BRANCH="18.0"; break;;
            6) return 1;;
            *) 
                echo -e "${RED}Invalid choice. Please select 1-6.${NC}"
                sleep 2
                ;;
        esac
    done
    
    echo -e "${GREEN}Selected Odoo version: $OE_BRANCH${NC}"
    log_message "INFO" "User selected Odoo version: $OE_BRANCH"
    return 0
}

# Installation confirmation
confirm_installation() {
    clear
    display_billboard "Installation Confirmation"
    
    echo -e "${BOLD}${WHITE}Installation Summary:${NC}"
    echo -e "  ${CYAN}Odoo Version:${NC} $OE_BRANCH"
    echo -e "  ${CYAN}System User:${NC} $OE_USER"
    echo -e "  ${CYAN}Domain:${NC} ${DOMAIN_NAME:-"IP-based access"}"
    echo -e "  ${CYAN}Install Nginx:${NC} $INSTALL_NGINX"
    if [ "$INSTALL_NGINX" = "true" ]; then
        echo -e "  ${CYAN}SSL Certificate:${NC} $SSL_TYPE"
    fi
    echo -e "  ${CYAN}Install wkhtmltopdf:${NC} $INSTALL_WKHTMLTOPDF"
    echo -e "  ${CYAN}Enterprise Features:${NC} $IS_ENTERPRISE"
    echo -e "  ${CYAN}Log File:${NC} $LOG_FILE"
    echo
    echo -e "${YELLOW}${BOLD}WARNING:${NC} This installation will:"
    echo -e "  • Modify system packages and configurations"
    echo -e "  • Create system users and directories"
    echo -e "  • Install and configure PostgreSQL"
    echo -e "  • Download and install Odoo from source"
    if [ "$INSTALL_NGINX" = "true" ]; then
        echo -e "  • Install and configure Nginx with SSL"
    fi
    echo
    
    while true; do
        read -rp "$(echo -e ${BOLD}${WHITE}Do you want to proceed with the installation? [y/N]: ${NC})" confirm
        case "$confirm" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                echo -e "${YELLOW}Installation cancelled by user.${NC}"
                return 1
                ;;
            *)
                echo -e "${RED}Please answer yes (y) or no (n).${NC}"
                ;;
        esac
    done
}

# Custom installation menu
custom_installation_menu() {
    echo -e "${YELLOW}Custom installation options coming in future version...${NC}"
    sleep 2
}

# System check only
system_check_only() {
    clear
    display_billboard "System Requirements Check"
    
    echo -e "${CYAN}Checking system requirements...${NC}"
    echo
    
    check_system_requirements
    local result=$?
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}${BOLD}✓ All system requirements met!${NC}"
    else
        echo -e "${RED}${BOLD}✗ $result requirement(s) not met.${NC}"
    fi
    
    echo
    read -rp "Press Enter to continue..."
}

# View log
view_log() {
    if [ -f "$LOG_FILE" ]; then
        less "$LOG_FILE"
    else
        echo -e "${YELLOW}No log file found.${NC}"
        sleep 2
    fi
}

# Show help
show_help() {
    clear
    display_billboard "Help & Documentation"
    
    echo -e "${BOLD}${WHITE}Enhanced Odoo Installation Script Help${NC}"
    echo
    echo -e "${CYAN}This script automates the installation of Odoo on Ubuntu 22.04.${NC}"
    echo
    echo -e "${BOLD}New Features in v2.1:${NC}"
    echo -e "  • Domain configuration and DNS verification"
    echo -e "  • Official Nginx installation (latest version)"
    echo -e "  • Let's Encrypt SSL certificate automation"
    echo -e "  • Self-signed SSL certificate generation"
    echo -e "  • Dynamic Odoo configuration generation"
    echo
    echo -e "${BOLD}System Requirements:${NC}"
    echo -e "  • Ubuntu 22.04 LTS"
    echo -e "  • Minimum 2GB RAM (4GB recommended)"
    echo -e "  • Minimum 10GB free disk space"
    echo -e "  • Internet connection"
    echo -e "  • Root/sudo privileges"
    echo -e "  • Domain name (optional, for SSL)"
    echo
    
    read -rp "Press Enter to continue..."
}

# Continue with the rest of the script...


#==============================================================================
# INSTALLATION FUNCTIONS
#==============================================================================

# Step 1: Pre-flight checks
step_preflight_checks() {
    show_step_header 1 "Pre-flight Checks" "Validating system requirements and configuration"
    
    # Check if running as root
    check_root
    
    # System requirements check
    if ! check_system_requirements; then
        log_message "ERROR" "System requirements check failed"
        exit 1
    fi
    
    # Validate Odoo version
    if ! validate_odoo_version; then
        log_message "ERROR" "Invalid Odoo version configuration"
        exit 1
    fi
    
    log_message "INFO" "Pre-flight checks completed successfully"
}

# Step 2: System preparation
step_system_preparation() {
    show_step_header 2 "System Preparation" "Creating users and updating system packages"
    
    # Create Odoo user and group
    execute_command "groupadd -f $OE_USER" "Creating Odoo group"
    execute_command "useradd --create-home -d /home/$OE_USER --shell /bin/bash -g $OE_USER $OE_USER 2>/dev/null || true" "Creating Odoo user"
    execute_command "usermod -aG sudo $OE_USER" "Adding Odoo user to sudo group"
    
    # Update system packages
    execute_command "apt-get update" "Updating package lists"
    execute_command "apt-get upgrade -y" "Upgrading system packages"
    execute_command "apt install -y zip gdebi net-tools curl wget gnupg2 software-properties-common" "Installing basic tools"
    
    # Configure localization
    execute_command "export LC_ALL=en_US.UTF-8 && export LC_CTYPE=en_US.UTF-8" "Setting locale variables"
    execute_command "dpkg-reconfigure -f noninteractive locales" "Configuring locales"
    
    log_message "INFO" "System preparation completed successfully"
}

# Step 3: Database setup
step_database_setup() {
    show_step_header 3 "Database Setup" "Installing and configuring PostgreSQL database"
    
    # Add PostgreSQL repository
    execute_command "sh -c 'echo \"deb [arch=amd64] http://apt.postgresql.org/pub/repos/apt jammy-pgdg main\" > /etc/apt/sources.list.d/pgdg.list'" "Adding PostgreSQL repository"
    
    # Add PostgreSQL signing key with error handling
    if ! execute_command "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -" "Adding PostgreSQL signing key"; then
        log_message "WARNING" "Failed to add PostgreSQL key via apt-key, trying alternative method"
        execute_command "wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/postgresql.gpg > /dev/null" "Adding PostgreSQL signing key (alternative method)"
    fi
    
    # Update package lists
    execute_command "apt-get update" "Updating package lists with PostgreSQL repository"
    
    # Install PostgreSQL
    execute_command "apt-get install -y postgresql-16 postgresql-server-dev-16" "Installing PostgreSQL 16"
    
    # Create PostgreSQL user for Odoo
    execute_command "su - postgres -c \"createuser -s $OE_USER\" 2>/dev/null || true" "Creating PostgreSQL user for Odoo"
    
    # Verify PostgreSQL installation
    if ! systemctl is-active --quiet postgresql; then
        log_message "ERROR" "PostgreSQL service is not running"
        execute_command "systemctl start postgresql" "Starting PostgreSQL service"
        execute_command "systemctl enable postgresql" "Enabling PostgreSQL service"
    fi
    
    log_message "INFO" "Database setup completed successfully"
}

# Step 4: Dependencies installation
step_dependencies_installation() {
    show_step_header 4 "Dependencies Installation" "Installing Python packages and system libraries"
    
    # Install system dependencies
    local system_packages=(
        "git" "python3-pip" "build-essential" "wget" "python3-dev" 
        "python3-venv" "python3-wheel" "libfreetype6-dev" "libxml2-dev" 
        "libzip-dev" "libldap2-dev" "libsasl2-dev" "python3-setuptools" 
        "node-less" "libjpeg-dev" "zlib1g-dev" "libpq-dev" "libtiff5-dev" 
        "libjpeg8-dev" "libopenjp2-7-dev" "liblcms2-dev" "libwebp-dev" 
        "libharfbuzz-dev" "libfribidi-dev" "libxcb1-dev" "libwww-perl"
        "gsfonts" "libcairo2-dev" "python3-cairo"
    )
    
    for package in "${system_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            execute_command "apt-get install -y $package" "Installing $package"
        else
            log_message "INFO" "$package is already installed"
        fi
    done
    
    # Install Python libraries
    execute_command "pip3 install gdata psycogreen" "Installing Python data libraries"
    execute_command "pip3 install suds" "Installing SUDS library"
    execute_command "pip3 install rtPyCairo" "Installing Cairo Python bindings"
    
    # Install Node.js and npm packages
    execute_command "apt-get install -y ca-certificates curl gnupg" "Installing Node.js prerequisites"
    execute_command "mkdir -p /etc/apt/keyrings" "Creating keyrings directory"
    
    if ! execute_command "curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg" "Adding Node.js repository key"; then
        log_message "ERROR" "Failed to add Node.js repository key"
        return 1
    fi
    
    execute_command "echo 'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main' | tee /etc/apt/sources.list.d/nodesource.list" "Adding Node.js repository"
    execute_command "apt-get update" "Updating package lists with Node.js repository"
    execute_command "apt-get install -y nodejs" "Installing Node.js"
    
    # Create symbolic link for node
    execute_command "ln -sf /usr/bin/nodejs /usr/bin/node" "Creating Node.js symbolic link"
    
    # Install npm packages for Enterprise features
    if [ "$IS_ENTERPRISE" = "True" ]; then
        execute_command "npm install -g less" "Installing Less CSS preprocessor"
        execute_command "npm install -g less-plugin-clean-css" "Installing Less clean CSS plugin"
        execute_command "npm install -g rtlcss" "Installing RTL CSS processor"
    fi
    
    log_message "INFO" "Dependencies installation completed successfully"
}

# Step 5: Wkhtmltopdf installation
step_wkhtmltopdf_installation() {
    show_step_header 5 "Wkhtmltopdf Installation" "Installing PDF generation library"
    
    if [ "$INSTALL_WKHTMLTOPDF" = "True" ]; then
        # Determine architecture
        if [ "$(getconf LONG_BIT)" == "64" ]; then
            local wkhtml_url="$WKHTML_X64"
        else
            local wkhtml_url="$WKHTML_X32"
        fi
        
        local wkhtml_file=$(basename "$wkhtml_url")
        
        # Download wkhtmltopdf
        if ! execute_command "wget -O /tmp/$wkhtml_file $wkhtml_url" "Downloading wkhtmltopdf"; then
            log_message "ERROR" "Failed to download wkhtmltopdf"
            return 1
        fi
        
        # Install wkhtmltopdf
        execute_command "gdebi --non-interactive /tmp/$wkhtml_file" "Installing wkhtmltopdf"
        
        # Cleanup
        execute_command "rm -f /tmp/$wkhtml_file" "Cleaning up wkhtmltopdf installer"
        
        # Verify installation
        if command -v wkhtmltopdf &> /dev/null; then
            log_message "INFO" "Wkhtmltopdf installed successfully: $(wkhtmltopdf --version | head -n1)"
        else
            log_message "ERROR" "Wkhtmltopdf installation verification failed"
            return 1
        fi
    else
        log_message "INFO" "Wkhtmltopdf installation skipped by user configuration"
    fi
    
    log_message "INFO" "Wkhtmltopdf installation completed"
}

# Step 6: Odoo installation
step_odoo_installation() {
    show_step_header 6 "Odoo Installation" "Downloading and configuring Odoo source code"
    
    # Install additional Python packages
    local python_packages=(
        "python3-dev" "python3-asn1crypto" "python3-babel" "python3-bs4" 
        "python3-cffi-backend" "python3-cryptography" "python3-dateutil" 
        "python3-docutils" "python3-feedparser" "python3-funcsigs" 
        "python3-gevent" "python3-greenlet" "python3-html2text" 
        "python3-html5lib" "python3-jinja2" "python3-lxml" "python3-mako" 
        "python3-markupsafe" "python3-mock" "python3-ofxparse" 
        "python3-openssl" "python3-passlib" "python3-pbr" "python3-pil" 
        "python3-psutil" "python3-psycopg2" "python3-pydot" "python3-pygments" 
        "python3-pypdf2" "python3-renderpm" "python3-reportlab" 
        "python3-reportlab-accel" "python3-roman" "python3-serial" 
        "python3-stdnum" "python3-suds" "python3-tz" "python3-usb" 
        "python3-werkzeug" "python3-xlsxwriter" "python3-yaml"
    )
    
    for package in "${python_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            execute_command "apt-get install -y $package" "Installing $package"
        fi
    done
    
    # Install Python packages via pip
    execute_command "easy_install greenlet" "Installing greenlet"
    execute_command "easy_install gevent" "Installing gevent"
    
    # Create Odoo directories
    execute_command "mkdir -p /odoo" "Creating Odoo directory"
    execute_command "mkdir -p /etc/odoo" "Creating Odoo configuration directory"
    execute_command "mkdir -p /var/log/odoo" "Creating Odoo log directory"
    
    # Create log file
    execute_command "touch /var/log/odoo/odoo-server.log" "Creating Odoo log file"
    
    # Set proper ownership
    execute_command "chown -R $OE_USER:$OE_USER /var/log/odoo" "Setting ownership for log directory"
    execute_command "chown -R $OE_USER:$OE_USER /etc/odoo" "Setting ownership for configuration directory"
    
    # Clone Odoo repository
    cd /odoo || exit 1
    if ! execute_command "git clone --depth 1 --branch $OE_BRANCH https://www.github.com/odoo/odoo" "Cloning Odoo repository"; then
        log_message "ERROR" "Failed to clone Odoo repository"
        return 1
    fi
    
    # Set ownership for Odoo directory
    execute_command "chown -R $OE_USER:$OE_USER /odoo" "Setting ownership for Odoo directory"
    
    # Install Odoo Python requirements
    execute_command "su - $OE_USER -s /bin/bash -c \"pip3 install -r https://raw.githubusercontent.com/odoo/odoo/$OE_BRANCH/requirements.txt --user\"" "Installing Odoo Python requirements"
    execute_command "su - $OE_USER -s /bin/bash -c \"pip3 install phonenumbers --user\"" "Installing phonenumbers library"
    
    log_message "INFO" "Odoo installation completed successfully"
}

#==============================================================================
# NGINX INSTALLATION AND CONFIGURATION
#==============================================================================

# Install official Nginx (latest version)
install_official_nginx() {
    echo -e "${CYAN}Installing official Nginx (latest version)...${NC}"
    
    # Remove any existing Nginx installation
    execute_command "apt-get remove -y nginx nginx-common nginx-core" "Removing existing Nginx packages"
    execute_command "apt-get autoremove -y" "Cleaning up unused packages"
    
    # Add official Nginx repository
    execute_command "curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -" "Adding Nginx signing key"
    execute_command "echo 'deb https://nginx.org/packages/ubuntu/ jammy nginx' > /etc/apt/sources.list.d/nginx.list" "Adding Nginx repository"
    execute_command "echo 'deb-src https://nginx.org/packages/ubuntu/ jammy nginx' >> /etc/apt/sources.list.d/nginx.list" "Adding Nginx source repository"
    
    # Set repository priority
    cat > /etc/apt/preferences.d/99nginx << EOF
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
EOF
    
    # Update and install Nginx
    execute_command "apt-get update" "Updating package lists with Nginx repository"
    execute_command "apt-get install -y nginx" "Installing official Nginx"
    
    # Verify Nginx installation
    local nginx_version=$(nginx -v 2>&1 | cut -d' ' -f3 | cut -d'/' -f2)
    log_message "INFO" "Nginx installed successfully: version $nginx_version"
    
    # Enable and start Nginx
    execute_command "systemctl enable nginx" "Enabling Nginx service"
    execute_command "systemctl start nginx" "Starting Nginx service"
    
    # Verify Nginx is running
    if systemctl is-active --quiet nginx; then
        log_message "INFO" "Nginx service is running"
    else
        log_message "ERROR" "Nginx service failed to start"
        return 1
    fi
}

# Generate self-signed SSL certificate
generate_self_signed_ssl() {
    echo -e "${CYAN}Generating self-signed SSL certificate...${NC}"
    
    # Create SSL directory
    execute_command "mkdir -p /etc/ssl/nginx" "Creating SSL directory"
    
    # Generate private key and certificate
    execute_command "openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/nginx/server.key \
        -out /etc/ssl/nginx/server.crt \
        -subj \"/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$DOMAIN_NAME\"" "Generating SSL certificate"
    
    # Set proper permissions
    execute_command "chmod 600 /etc/ssl/nginx/server.key" "Setting SSL key permissions"
    execute_command "chmod 644 /etc/ssl/nginx/server.crt" "Setting SSL certificate permissions"
    
    log_message "INFO" "Self-signed SSL certificate generated successfully"
}

# Install and configure Let's Encrypt
install_letsencrypt_ssl() {
    echo -e "${CYAN}Installing Let's Encrypt SSL certificate...${NC}"
    
    # Install snapd if not present
    if ! command -v snap &> /dev/null; then
        execute_command "apt-get install -y snapd" "Installing snapd"
        execute_command "systemctl enable --now snapd.socket" "Enabling snapd"
        execute_command "ln -s /var/lib/snapd/snap /snap" "Creating snap symlink"
    fi
    
    # Remove any existing certbot packages
    execute_command "apt-get remove -y certbot" "Removing existing certbot packages"
    
    # Install certbot via snap
    execute_command "snap install --classic certbot" "Installing Certbot via snap"
    execute_command "ln -sf /snap/bin/certbot /usr/bin/certbot" "Creating Certbot symlink"
    
    # Create temporary Nginx configuration for domain verification
    create_temporary_nginx_config
    
    # Reload Nginx with temporary config
    execute_command "nginx -t" "Testing Nginx configuration"
    execute_command "systemctl reload nginx" "Reloading Nginx"
    
    # Get SSL certificate
    if execute_command "certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos --email admin@$DOMAIN_NAME" "Obtaining Let's Encrypt certificate"; then
        log_message "INFO" "Let's Encrypt SSL certificate obtained successfully"
        
        # Test automatic renewal
        execute_command "certbot renew --dry-run" "Testing automatic renewal"
    else
        log_message "ERROR" "Failed to obtain Let's Encrypt certificate, falling back to self-signed"
        SSL_TYPE="self-signed"
        generate_self_signed_ssl
    fi
}

# Create temporary Nginx configuration for Let's Encrypt verification
create_temporary_nginx_config() {
    cat > /etc/nginx/conf.d/temp_odoo.conf << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    
    location / {
        return 200 'Temporary configuration for SSL setup';
        add_header Content-Type text/plain;
    }
}
EOF
    log_message "INFO" "Created temporary Nginx configuration"
}

# Create Nginx configuration for Odoo
create_nginx_odoo_config() {
    echo -e "${CYAN}Creating Nginx configuration for Odoo...${NC}"
    
    # Remove temporary configuration
    execute_command "rm -f /etc/nginx/conf.d/temp_odoo.conf" "Removing temporary configuration"
    
    # Determine SSL certificate paths
    local ssl_cert_path
    local ssl_key_path
    
    if [ "$SSL_TYPE" = "letsencrypt" ]; then
        ssl_cert_path="/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
        ssl_key_path="/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem"
    else
        ssl_cert_path="/etc/ssl/nginx/server.crt"
        ssl_key_path="/etc/ssl/nginx/server.key"
    fi
    
    # Create Nginx configuration based on template
    cat > /etc/nginx/conf.d/odoo.conf << EOF
#odoo server
upstream odoo {
  server 127.0.0.1:8069;
}
upstream odoochat {
  server 127.0.0.1:8072;
}
map \$http_upgrade \$connection_upgrade {
  default upgrade;
  ''      close;
}

# http -> https
server {
  listen 80;
  server_name $DOMAIN_NAME;
  rewrite ^(.*) https://\$host\$1 permanent;
}

server {
  listen 443 ssl;
  server_name $DOMAIN_NAME;
  proxy_read_timeout 720s;
  proxy_connect_timeout 720s;
  proxy_send_timeout 720s;

  # SSL parameters
  ssl_certificate $ssl_cert_path;
  ssl_certificate_key $ssl_key_path;
  ssl_session_timeout 30m;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
  ssl_prefer_server_ciphers off;

  # log
  access_log /var/log/nginx/odoo.access.log;
  error_log /var/log/nginx/odoo.error.log;

  # Redirect websocket requests to odoo gevent port
  location /websocket {
    proxy_pass http://odoochat;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;
    proxy_set_header X-Forwarded-Host \$http_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    proxy_cookie_flags session_id samesite=lax secure;
  }

  # Redirect requests to odoo backend server
  location / {
    # Add Headers for odoo proxy mode
    proxy_set_header X-Forwarded-Host \$http_host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_redirect off;
    proxy_pass http://odoo;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
    proxy_cookie_flags session_id samesite=lax secure;
  }

  # common gzip
  gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
  gzip on;
}
EOF
    
    # Test Nginx configuration
    if execute_command "nginx -t" "Testing Nginx configuration"; then
        execute_command "systemctl reload nginx" "Reloading Nginx with Odoo configuration"
        log_message "INFO" "Nginx configuration created and loaded successfully"
    else
        log_message "ERROR" "Nginx configuration test failed"
        return 1
    fi
}

#==============================================================================
# DYNAMIC ODOO CONFIGURATION
#==============================================================================

# Generate dynamic Odoo configuration
generate_odoo_config() {
    echo -e "${CYAN}Generating dynamic Odoo configuration...${NC}"
    
    # Generate a secure admin password
    local admin_password=$(openssl rand -base64 32)
    
    # Create initial configuration file
    cat > /etc/odoo/odoo.conf << EOF
[options]
; This is the password that allows database operations:
admin_passwd = $admin_password
db_host = localhost
db_port = 5432
db_user = $OE_USER
db_password = False
addons_path = /odoo/odoo/addons
logfile = /var/log/odoo/odoo-server.log
log_level = info
EOF
    
    # Set proper ownership and permissions
    execute_command "chown $OE_USER:$OE_USER /etc/odoo/odoo.conf" "Setting ownership for configuration file"
    execute_command "chmod 640 /etc/odoo/odoo.conf" "Setting permissions for configuration file"
    
    # Generate configuration using Odoo's built-in method
    echo -e "${CYAN}Generating configuration using Odoo...${NC}"
    
    # Run Odoo configuration generation as the odoo user
    if execute_command "su - $OE_USER -s /bin/bash -c 'cd /odoo/odoo && ./odoo-bin -w $admin_password -s -c /etc/odoo/odoo.conf --stop-after-init'" "Generating Odoo configuration"; then
        log_message "INFO" "Odoo configuration generated successfully"
        
        # Add proxy mode configuration if Nginx is installed
        if [ "$INSTALL_NGINX" = "true" ]; then
            echo "" >> /etc/odoo/odoo.conf
            echo "; Proxy mode configuration" >> /etc/odoo/odoo.conf
            echo "proxy_mode = True" >> /etc/odoo/odoo.conf
            log_message "INFO" "Added proxy mode configuration for Nginx"
        fi
        
        # Store admin password for user reference
        echo "ODOO_ADMIN_PASSWORD=$admin_password" > /root/odoo_admin_password.txt
        chmod 600 /root/odoo_admin_password.txt
        log_message "INFO" "Admin password saved to /root/odoo_admin_password.txt"
        
    else
        log_message "ERROR" "Failed to generate Odoo configuration"
        return 1
    fi
}

# Continue with remaining functions...


# Step 7: Service configuration with Nginx
step_service_configuration() {
    show_step_header 7 "Service Configuration" "Configuring Odoo system service and web server"
    
    # Create Odoo service file
    create_odoo_service_file
    
    # Generate dynamic Odoo configuration
    generate_odoo_config
    
    # Reload systemd and enable Odoo service
    execute_command "systemctl daemon-reload" "Reloading systemd daemon"
    execute_command "systemctl enable odoo" "Enabling Odoo service"
    
    # Install and configure Nginx if requested
    if [ "$INSTALL_NGINX" = "true" ]; then
        install_official_nginx
        
        # Configure SSL certificates
        if [ "$SSL_TYPE" = "letsencrypt" ]; then
            install_letsencrypt_ssl
        else
            generate_self_signed_ssl
        fi
        
        # Create Nginx configuration for Odoo
        create_nginx_odoo_config
    fi
    
    # Start Odoo service
    if execute_command "systemctl start odoo" "Starting Odoo service"; then
        sleep 5
        if systemctl is-active --quiet odoo; then
            log_message "INFO" "Odoo service started successfully"
        else
            log_message "ERROR" "Odoo service failed to start"
            execute_command "systemctl status odoo" "Checking Odoo service status" true
        fi
    fi
    
    log_message "INFO" "Service configuration completed successfully"
}

# Step 8: Final setup and validation
step_final_setup() {
    show_step_header 8 "Final Setup" "Completing installation and running validation tests"
    
    # Install additional tools
    execute_command "apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python" "Installing additional system tools"
    
    # Validate installation
    validate_installation
    
    # Generate installation report
    generate_installation_report
    
    log_message "INFO" "Final setup completed successfully"
}

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================

# Create Odoo service file
create_odoo_service_file() {
    cat > /etc/systemd/system/odoo.service << EOF
[Unit]
Description=Odoo
Documentation=http://www.odoo.com
Requires=postgresql.service
After=postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=$OE_USER
Group=$OE_USER
ExecStart=/odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF
    log_message "INFO" "Created Odoo service file"
}

# Validate installation
validate_installation() {
    local validation_errors=0
    
    echo -e "${CYAN}Running installation validation tests...${NC}"
    
    # Check if Odoo service is running
    if systemctl is-active --quiet odoo; then
        echo -e "${GREEN}✓${NC} Odoo service is running"
        log_message "INFO" "Validation: Odoo service is running"
    else
        echo -e "${RED}✗${NC} Odoo service is not running"
        log_message "ERROR" "Validation: Odoo service is not running"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check if PostgreSQL is running
    if systemctl is-active --quiet postgresql; then
        echo -e "${GREEN}✓${NC} PostgreSQL service is running"
        log_message "INFO" "Validation: PostgreSQL service is running"
    else
        echo -e "${RED}✗${NC} PostgreSQL service is not running"
        log_message "ERROR" "Validation: PostgreSQL service is not running"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check if Nginx is running (if installed)
    if [ "$INSTALL_NGINX" = "true" ]; then
        if systemctl is-active --quiet nginx; then
            echo -e "${GREEN}✓${NC} Nginx service is running"
            log_message "INFO" "Validation: Nginx service is running"
        else
            echo -e "${RED}✗${NC} Nginx service is not running"
            log_message "ERROR" "Validation: Nginx service is not running"
            validation_errors=$((validation_errors + 1))
        fi
    fi
    
    # Check if Odoo directories exist
    if [ -d "/odoo/odoo" ]; then
        echo -e "${GREEN}✓${NC} Odoo source code directory exists"
        log_message "INFO" "Validation: Odoo source code directory exists"
    else
        echo -e "${RED}✗${NC} Odoo source code directory missing"
        log_message "ERROR" "Validation: Odoo source code directory missing"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Check if configuration file exists
    if [ -f "/etc/odoo/odoo.conf" ]; then
        echo -e "${GREEN}✓${NC} Odoo configuration file exists"
        log_message "INFO" "Validation: Odoo configuration file exists"
    else
        echo -e "${RED}✗${NC} Odoo configuration file missing"
        log_message "ERROR" "Validation: Odoo configuration file missing"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Test network connectivity to Odoo
    if systemctl is-active --quiet odoo; then
        sleep 10  # Give Odoo time to fully start
        
        if [ "$INSTALL_NGINX" = "true" ]; then
            # Test HTTPS access
            if curl -k -s "https://$DOMAIN_NAME" > /dev/null; then
                echo -e "${GREEN}✓${NC} Odoo web interface is accessible via HTTPS"
                log_message "INFO" "Validation: Odoo HTTPS interface accessible"
            else
                echo -e "${YELLOW}⚠${NC} Odoo HTTPS interface may not be ready yet"
                log_message "WARNING" "Validation: Odoo HTTPS interface not immediately accessible"
            fi
        else
            # Test direct HTTP access
            if curl -s http://localhost:8069 > /dev/null; then
                echo -e "${GREEN}✓${NC} Odoo web interface is accessible"
                log_message "INFO" "Validation: Odoo web interface accessible"
            else
                echo -e "${YELLOW}⚠${NC} Odoo web interface may not be ready yet"
                log_message "WARNING" "Validation: Odoo web interface not immediately accessible"
            fi
        fi
    fi
    
    # Check SSL certificate (if applicable)
    if [ "$INSTALL_NGINX" = "true" ] && [ "$SSL_TYPE" = "letsencrypt" ]; then
        if [ -f "/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem" ]; then
            echo -e "${GREEN}✓${NC} Let's Encrypt SSL certificate is installed"
            log_message "INFO" "Validation: Let's Encrypt SSL certificate installed"
        else
            echo -e "${RED}✗${NC} Let's Encrypt SSL certificate missing"
            log_message "ERROR" "Validation: Let's Encrypt SSL certificate missing"
            validation_errors=$((validation_errors + 1))
        fi
    elif [ "$INSTALL_NGINX" = "true" ] && [ "$SSL_TYPE" = "self-signed" ]; then
        if [ -f "/etc/ssl/nginx/server.crt" ]; then
            echo -e "${GREEN}✓${NC} Self-signed SSL certificate is installed"
            log_message "INFO" "Validation: Self-signed SSL certificate installed"
        else
            echo -e "${RED}✗${NC} Self-signed SSL certificate missing"
            log_message "ERROR" "Validation: Self-signed SSL certificate missing"
            validation_errors=$((validation_errors + 1))
        fi
    fi
    
    return $validation_errors
}

# Generate installation report
generate_installation_report() {
    local report_file="/tmp/odoo_installation_report_$(date +%Y%m%d_%H%M%S).txt"
    
    # Read admin password if available
    local admin_password="Not available"
    if [ -f "/root/odoo_admin_password.txt" ]; then
        admin_password=$(grep "ODOO_ADMIN_PASSWORD=" /root/odoo_admin_password.txt | cut -d'=' -f2)
    fi
    
    cat > "$report_file" << EOF
===============================================================================
                        ENHANCED ODOO INSTALLATION REPORT
===============================================================================

Installation Date: $(date)
Script Version: $SCRIPT_VERSION
System: $(lsb_release -d | cut -f2)

CONFIGURATION:
- Odoo Version: $OE_BRANCH
- System User: $OE_USER
- Domain: $DOMAIN_NAME
- Nginx Installed: $INSTALL_NGINX
- SSL Type: $SSL_TYPE
- Wkhtmltopdf: $INSTALL_WKHTMLTOPDF
- Enterprise: $IS_ENTERPRISE

SERVICES STATUS:
- Odoo Service: $(systemctl is-active odoo)
- PostgreSQL Service: $(systemctl is-active postgresql)
$([ "$INSTALL_NGINX" = "true" ] && echo "- Nginx Service: $(systemctl is-active nginx)")

DIRECTORIES:
- Odoo Source: /odoo/odoo
- Configuration: /etc/odoo/odoo.conf
- Logs: /var/log/odoo/odoo-server.log

NETWORK ACCESS:
$(if [ "$INSTALL_NGINX" = "true" ]; then
    echo "- Odoo Web Interface: https://$DOMAIN_NAME"
    echo "- HTTP Redirect: http://$DOMAIN_NAME (redirects to HTTPS)"
else
    echo "- Odoo Web Interface: http://$DOMAIN_NAME:8069"
fi)
- Database Management: $([ "$INSTALL_NGINX" = "true" ] && echo "https://$DOMAIN_NAME/web/database/manager" || echo "http://$DOMAIN_NAME:8069/web/database/manager")

SECURITY:
- Admin Password: $admin_password
$([ "$INSTALL_NGINX" = "true" ] && echo "- SSL Certificate: $SSL_TYPE")
$([ "$SSL_TYPE" = "letsencrypt" ] && echo "- Auto-renewal: Enabled via certbot")

IMPORTANT FILES:
- Odoo Configuration: /etc/odoo/odoo.conf
- Odoo Service: /etc/systemd/system/odoo.service
$([ "$INSTALL_NGINX" = "true" ] && echo "- Nginx Configuration: /etc/nginx/conf.d/odoo.conf")
$([ "$SSL_TYPE" = "self-signed" ] && echo "- SSL Certificate: /etc/ssl/nginx/server.crt")
$([ "$SSL_TYPE" = "letsencrypt" ] && echo "- SSL Certificate: /etc/letsencrypt/live/$DOMAIN_NAME/")
- Admin Password File: /root/odoo_admin_password.txt

NEXT STEPS:
1. Access Odoo at $([ "$INSTALL_NGINX" = "true" ] && echo "https://$DOMAIN_NAME" || echo "http://$DOMAIN_NAME:8069")
2. Create your first database using the admin password above
3. Configure your Odoo instance
$([ "$SSL_TYPE" = "self-signed" ] && echo "4. Consider replacing self-signed certificate with Let's Encrypt for production")
5. Set up backup procedures
6. Configure firewall rules

TROUBLESHOOTING:
- Check Odoo status: systemctl status odoo
- View Odoo logs: tail -f /var/log/odoo/odoo-server.log
- Restart Odoo: systemctl restart odoo
$([ "$INSTALL_NGINX" = "true" ] && echo "- Check Nginx status: systemctl status nginx")
$([ "$INSTALL_NGINX" = "true" ] && echo "- View Nginx logs: tail -f /var/log/nginx/odoo.error.log")
$([ "$SSL_TYPE" = "letsencrypt" ] && echo "- Test SSL renewal: certbot renew --dry-run")
- Installation log: $LOG_FILE

===============================================================================
EOF
    
    echo -e "${GREEN}Installation report generated: $report_file${NC}"
    log_message "INFO" "Installation report generated: $report_file"
    
    # Also save to a standard location
    cp "$report_file" "/root/odoo_installation_report.txt"
    log_message "INFO" "Installation report also saved to: /root/odoo_installation_report.txt"
}

# Installation success message
show_success_message() {
    clear
    display_billboard "Installation Complete!"
    
    echo -e "${GREEN}${BOLD}🎉 Enhanced Odoo $OE_BRANCH has been successfully installed! 🎉${NC}"
    echo
    
    if [ "$INSTALL_NGINX" = "true" ]; then
        echo -e "${CYAN}Access your Odoo instance at:${NC}"
        echo -e "  ${BOLD}${WHITE}https://$DOMAIN_NAME${NC}"
        echo -e "  ${YELLOW}Note: HTTP requests will automatically redirect to HTTPS${NC}"
    else
        echo -e "${CYAN}Access your Odoo instance at:${NC}"
        echo -e "  ${BOLD}${WHITE}http://$DOMAIN_NAME:8069${NC}"
    fi
    
    echo
    echo -e "${CYAN}Database management:${NC}"
    if [ "$INSTALL_NGINX" = "true" ]; then
        echo -e "  ${BOLD}${WHITE}https://$DOMAIN_NAME/web/database/manager${NC}"
    else
        echo -e "  ${BOLD}${WHITE}http://$DOMAIN_NAME:8069/web/database/manager${NC}"
    fi
    
    echo
    echo -e "${CYAN}Important credentials:${NC}"
    if [ -f "/root/odoo_admin_password.txt" ]; then
        local admin_password=$(grep "ODOO_ADMIN_PASSWORD=" /root/odoo_admin_password.txt | cut -d'=' -f2)
        echo -e "  ${YELLOW}Admin Password:${NC} $admin_password"
        echo -e "  ${YELLOW}Password File:${NC} /root/odoo_admin_password.txt"
    fi
    
    echo
    echo -e "${CYAN}Important files and directories:${NC}"
    echo -e "  ${YELLOW}Configuration:${NC} /etc/odoo/odoo.conf"
    echo -e "  ${YELLOW}Log file:${NC} /var/log/odoo/odoo-server.log"
    echo -e "  ${YELLOW}Source code:${NC} /odoo/odoo"
    if [ "$INSTALL_NGINX" = "true" ]; then
        echo -e "  ${YELLOW}Nginx config:${NC} /etc/nginx/conf.d/odoo.conf"
    fi
    echo -e "  ${YELLOW}Installation log:${NC} $LOG_FILE"
    echo -e "  ${YELLOW}Installation report:${NC} /root/odoo_installation_report.txt"
    
    echo
    echo -e "${CYAN}Useful commands:${NC}"
    echo -e "  ${YELLOW}Check Odoo status:${NC} systemctl status odoo"
    echo -e "  ${YELLOW}Restart Odoo:${NC} systemctl restart odoo"
    echo -e "  ${YELLOW}View Odoo logs:${NC} tail -f /var/log/odoo/odoo-server.log"
    if [ "$INSTALL_NGINX" = "true" ]; then
        echo -e "  ${YELLOW}Check Nginx status:${NC} systemctl status nginx"
        echo -e "  ${YELLOW}View Nginx logs:${NC} tail -f /var/log/nginx/odoo.error.log"
    fi
    if [ "$SSL_TYPE" = "letsencrypt" ]; then
        echo -e "  ${YELLOW}Test SSL renewal:${NC} certbot renew --dry-run"
    fi
    
    echo
    echo -e "${BOLD}${WHITE}Thank you for using the Enhanced Odoo Installer!${NC}"
    echo
}

#==============================================================================
# MAIN EXECUTION FLOW
#==============================================================================

# Main installation function
main_installation() {
    local start_time=$(date +%s)
    
    # Execute all installation steps
    step_preflight_checks
    step_system_preparation
    step_database_setup
    step_dependencies_installation
    step_wkhtmltopdf_installation
    step_odoo_installation
    step_service_configuration
    step_final_setup
    
    # Calculate installation time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # Validate installation
    if validate_installation; then
        show_success_message
        log_message "INFO" "Installation completed successfully in ${minutes}m ${seconds}s"
    else
        echo -e "${RED}${BOLD}Installation completed with some issues.${NC}"
        echo -e "${YELLOW}Please check the log file for details: $LOG_FILE${NC}"
        echo -e "${YELLOW}Installation report: /root/odoo_installation_report.txt${NC}"
        log_message "WARNING" "Installation completed with validation errors in ${minutes}m ${seconds}s"
    fi
}

#==============================================================================
# SCRIPT EXECUTION
#==============================================================================

# Initialize logging
log_message "INFO" "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
log_message "INFO" "System: $(lsb_release -d | cut -f2)"
log_message "INFO" "User: $(whoami)"

# Show main menu
show_main_menu

# Start installation process
echo -e "${GREEN}${BOLD}Starting enhanced Odoo installation...${NC}"
echo

# Error handling for main execution
if ! main_installation; then
    log_message "ERROR" "Installation failed"
    echo -e "${RED}${BOLD}Installation failed!${NC}"
    echo -e "${YELLOW}Check the log file for details: $LOG_FILE${NC}"
    exit 1
fi

log_message "INFO" "Enhanced Odoo Installer v$SCRIPT_VERSION completed successfully"
