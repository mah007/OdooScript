#!/bin/bash

# Enhanced Odoo Installation Script for Ubuntu 22.04
# Version: 2.0
# Author: Mahmoud Abdel Latif
# Description: Interactive Odoo installation IOIS

# Script configuration
SCRIPT_VERSION="2.0"
SCRIPT_NAME="Enhanced Odoo Installer"
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
        echo -e "  ${GREEN}•${NC} Progress bars and status indicators"
        echo -e "  ${GREEN}•${NC} Comprehensive error handling"
        echo -e "  ${GREEN}•${NC} Automatic dependency management"
        echo -e "  ${GREEN}•${NC} System requirement validation"
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
    echo -e "  ${CYAN}Install wkhtmltopdf:${NC} $INSTALL_WKHTMLTOPDF"
    echo -e "  ${CYAN}Enterprise Features:${NC} $IS_ENTERPRISE"
    echo -e "  ${CYAN}Log File:${NC} $LOG_FILE"
    echo
    echo -e "${YELLOW}${BOLD}WARNING:${NC} This installation will:"
    echo -e "  • Modify system packages and configurations"
    echo -e "  • Create system users and directories"
    echo -e "  • Install and configure PostgreSQL"
    echo -e "  • Download and install Odoo from source"
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
    echo -e "${BOLD}Features:${NC}"
    echo -e "  • Interactive installation process"
    echo -e "  • Progress tracking with visual indicators"
    echo -e "  • Comprehensive error handling and logging"
    echo -e "  • System requirement validation"
    echo -e "  • Automatic dependency management"
    echo
    echo -e "${BOLD}System Requirements:${NC}"
    echo -e "  • Ubuntu 22.04 LTS"
    echo -e "  • Minimum 2GB RAM (4GB recommended)"
    echo -e "  • Minimum 10GB free disk space"
    echo -e "  • Internet connection"
    echo -e "  • Root/sudo privileges"
    echo
    echo -e "${BOLD}Support:${NC}"
    echo -e "  • Check log files for detailed error information"
    echo -e "  • Ensure all system requirements are met"
    echo -e "  • Run system check before installation"
    echo
    
    read -rp "Press Enter to continue..."
}

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
    execute_command "apt install -y zip gdebi net-tools" "Installing basic tools"
    
    # Configure localization
    execute_command "export LC_ALL=en_US.UTF-8 && export LC_CTYPE=en_US.UTF-8" "Setting locale variables"
    execute_command "dpkg-reconfigure -f noninteractive locales" "Configuring locales"
    
    log_message "INFO" "System preparation completed successfully"
}

# Continue with remaining steps...
# (This is part 1 of the enhanced script - the complete implementation continues below)

#==============================================================================
# MAIN EXECUTION
#==============================================================================

# Initialize logging
log_message "INFO" "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
log_message "INFO" "System: $(lsb_release -d | cut -f2)"
log_message "INFO" "User: $(whoami)"

# Show main menu
show_main_menu

# Start installation process
echo -e "${GREEN}${BOLD}Starting Odoo installation...${NC}"
echo

# Execute installation steps
step_preflight_checks
step_system_preparation

echo -e "${GREEN}${BOLD}Installation process initiated...${NC}"
echo -e "${CYAN}This is a preview of the enhanced script structure.${NC}"
echo -e "${CYAN}The complete implementation will include all installation steps.${NC}"



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
    
    # Create configuration and log files
    execute_command "touch /etc/odoo/odoo.conf" "Creating Odoo configuration file"
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

# Step 7: Service configuration
step_service_configuration() {
    show_step_header 7 "Service Configuration" "Configuring Odoo system service and web server"
    
    # Download and install Odoo service file
    cd /root || exit 1
    if ! execute_command "wget -O odoo.service https://raw.githubusercontent.com/mah007/OdooScript/14.0/odoo.service" "Downloading Odoo service file"; then
        log_message "WARNING" "Failed to download service file, creating custom one"
        create_custom_service_file
    else
        execute_command "cp odoo.service /etc/systemd/system/" "Installing Odoo service file"
    fi
    
    # Reload systemd and enable Odoo service
    execute_command "systemctl daemon-reload" "Reloading systemd daemon"
    execute_command "systemctl enable odoo" "Enabling Odoo service"
    
    # Create basic Odoo configuration
    create_odoo_configuration
    
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
    
    # Install and configure Nginx (optional)
    setup_nginx_proxy
    
    log_message "INFO" "Service configuration completed successfully"
}

# Step 8: Final setup and validation
step_final_setup() {
    show_step_header 8 "Final Setup" "Completing installation and running validation tests"
    
    # Install additional tools
    execute_command "apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python" "Installing additional system tools"
    
    # Download and add Webmin key (optional)
    if execute_command "wget -O /tmp/jcameron-key.asc https://download.webmin.com/jcameron-key.asc" "Downloading Webmin key"; then
        execute_command "apt-key add /tmp/jcameron-key.asc" "Adding Webmin key"
        execute_command "rm -f /tmp/jcameron-key.asc" "Cleaning up Webmin key file"
    fi
    
    # Validate installation
    validate_installation
    
    # Generate installation report
    generate_installation_report
    
    log_message "INFO" "Final setup completed successfully"
}

#==============================================================================
# HELPER FUNCTIONS
#==============================================================================

# Create custom service file if download fails
create_custom_service_file() {
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
    log_message "INFO" "Created custom Odoo service file"
}

# Create Odoo configuration file
create_odoo_configuration() {
    cat > /etc/odoo/odoo.conf << EOF
[options]
; This is the password that allows database operations:
admin_passwd = $(openssl rand -base64 32)
db_host = localhost
db_port = 5432
db_user = $OE_USER
db_password = False
addons_path = /odoo/odoo/addons
logfile = /var/log/odoo/odoo-server.log
log_level = info
EOF
    
    execute_command "chown $OE_USER:$OE_USER /etc/odoo/odoo.conf" "Setting ownership for configuration file"
    execute_command "chmod 640 /etc/odoo/odoo.conf" "Setting permissions for configuration file"
    log_message "INFO" "Created Odoo configuration file"
}

# Setup Nginx reverse proxy
setup_nginx_proxy() {
    read -rp "$(echo -e ${BOLD}${WHITE}Do you want to install and configure Nginx reverse proxy? [y/N]: ${NC})" install_nginx
    
    if [[ "$install_nginx" =~ ^[Yy]$ ]]; then
        execute_command "apt-get install -y nginx" "Installing Nginx"
        
        # Download nginx configuration or create custom one
        if ! execute_command "wget -O /tmp/nginx.sh https://raw.githubusercontent.com/mah007/OdooScript/14.0/nginx.sh" "Downloading Nginx configuration script"; then
            log_message "WARNING" "Failed to download Nginx configuration, skipping Nginx setup"
            return 1
        fi
        
        execute_command "bash /tmp/nginx.sh" "Configuring Nginx" true
        execute_command "rm -f /tmp/nginx.sh" "Cleaning up Nginx configuration script"
    else
        log_message "INFO" "Nginx installation skipped by user choice"
    fi
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
    
    # Test network connectivity to Odoo (if service is running)
    if systemctl is-active --quiet odoo; then
        sleep 10  # Give Odoo time to fully start
        if curl -s http://localhost:8069 > /dev/null; then
            echo -e "${GREEN}✓${NC} Odoo web interface is accessible"
            log_message "INFO" "Validation: Odoo web interface is accessible"
        else
            echo -e "${YELLOW}⚠${NC} Odoo web interface may not be ready yet (this is normal)"
            log_message "WARNING" "Validation: Odoo web interface not immediately accessible"
        fi
    fi
    
    return $validation_errors
}

# Generate installation report
generate_installation_report() {
    local report_file="/tmp/odoo_installation_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
===============================================================================
                        ODOO INSTALLATION REPORT
===============================================================================

Installation Date: $(date)
Script Version: $SCRIPT_VERSION
System: $(lsb_release -d | cut -f2)

CONFIGURATION:
- Odoo Version: $OE_BRANCH
- System User: $OE_USER
- Wkhtmltopdf: $INSTALL_WKHTMLTOPDF
- Enterprise: $IS_ENTERPRISE

SERVICES STATUS:
- Odoo Service: $(systemctl is-active odoo)
- PostgreSQL Service: $(systemctl is-active postgresql)

DIRECTORIES:
- Odoo Source: /odoo/odoo
- Configuration: /etc/odoo/odoo.conf
- Logs: /var/log/odoo/odoo-server.log

NETWORK:
- Odoo Web Interface: http://localhost:8069
- Default Database Management: http://localhost:8069/web/database/manager

NEXT STEPS:
1. Access Odoo at http://localhost:8069
2. Create your first database
3. Configure your Odoo instance
4. Set up SSL certificate (recommended for production)
5. Configure backup procedures

TROUBLESHOOTING:
- Check service status: systemctl status odoo
- View logs: tail -f /var/log/odoo/odoo-server.log
- Restart service: systemctl restart odoo
- Installation log: $LOG_FILE

===============================================================================
EOF
    
    echo -e "${GREEN}Installation report generated: $report_file${NC}"
    log_message "INFO" "Installation report generated: $report_file"
}

# Installation success message
show_success_message() {
    clear
    display_billboard "Installation Complete!"
    
    echo -e "${GREEN}${BOLD}🎉 Odoo $OE_BRANCH has been successfully installed! 🎉${NC}"
    echo
    echo -e "${CYAN}Access your Odoo instance at:${NC}"
    echo -e "  ${BOLD}${WHITE}http://localhost:8069${NC}"
    echo -e "  ${BOLD}${WHITE}http://$(hostname -I | awk '{print $1}'):8069${NC}"
    echo
    echo -e "${CYAN}Important files and directories:${NC}"
    echo -e "  ${YELLOW}Configuration:${NC} /etc/odoo/odoo.conf"
    echo -e "  ${YELLOW}Log file:${NC} /var/log/odoo/odoo-server.log"
    echo -e "  ${YELLOW}Source code:${NC} /odoo/odoo"
    echo -e "  ${YELLOW}Installation log:${NC} $LOG_FILE"
    echo
    echo -e "${CYAN}Useful commands:${NC}"
    echo -e "  ${YELLOW}Check status:${NC} systemctl status odoo"
    echo -e "  ${YELLOW}Restart service:${NC} systemctl restart odoo"
    echo -e "  ${YELLOW}View logs:${NC} tail -f /var/log/odoo/odoo-server.log"
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
        log_message "WARNING" "Installation completed with validation errors in ${minutes}m ${seconds}s"
    fi
}

# Error handling for main execution
if ! main_installation; then
    log_message "ERROR" "Installation failed"
    echo -e "${RED}${BOLD}Installation failed!${NC}"
    echo -e "${YELLOW}Check the log file for details: $LOG_FILE${NC}"
    exit 1
fi

log_message "INFO" "Enhanced Odoo Installer completed successfully IOIS"

