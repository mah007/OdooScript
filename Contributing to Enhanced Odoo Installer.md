# Contributing to Enhanced Odoo Installer

We love your input! We want to make contributing to Enhanced Odoo Installer as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## Pull Requests

Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Any contributions you make will be under the MIT Software License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using GitHub's [issue tracker](https://github.com/yourusername/enhanced-odoo-installer/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/yourusername/enhanced-odoo-installer/issues/new); it's that easy!

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

People *love* thorough bug reports. I'm not even kidding.

## Development Setup

### Prerequisites

- Ubuntu 22.04 LTS (for testing)
- Bash 4.0+
- Git
- Text editor of your choice

### Setting up the development environment

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/enhanced-odoo-installer.git
   cd enhanced-odoo-installer
   ```

2. **Create a development branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set up testing environment**
   ```bash
   # Use a virtual machine or container for testing
   # Never test on production systems
   ```

### Testing Guidelines

#### Manual Testing

1. **Test on clean Ubuntu 22.04 installations**
   - Use virtual machines or containers
   - Test both minimal and full installations

2. **Test different scenarios**
   - Domain-based installation
   - IP-based installation
   - With and without Nginx
   - Different Odoo versions (14.0-18.0)
   - Let's Encrypt and self-signed SSL

3. **Error scenario testing**
   - Network interruptions
   - Insufficient disk space
   - Missing dependencies
   - DNS misconfigurations

#### Automated Testing

```bash
# Syntax checking
bash -n enhanced_odoo_installer_complete.sh

# ShellCheck linting
shellcheck enhanced_odoo_installer_complete.sh

# Function testing
./test_functions.sh
```

### Code Style Guidelines

#### Bash Scripting Best Practices

1. **Use consistent indentation (4 spaces)**
   ```bash
   if [ "$condition" = "true" ]; then
       echo "Good indentation"
   fi
   ```

2. **Quote variables to prevent word splitting**
   ```bash
   # Good
   echo "$variable"
   
   # Bad
   echo $variable
   ```

3. **Use meaningful function and variable names**
   ```bash
   # Good
   install_postgresql_database()
   local database_user="odoo"
   
   # Bad
   install_db()
   local u="odoo"
   ```

4. **Add comments for complex logic**
   ```bash
   # Check if domain resolves to current server IP
   local domain_ip=$(dig +short "$DOMAIN_NAME" 2>/dev/null | tail -n1)
   if [ "$domain_ip" = "$SERVER_IP" ]; then
       echo "DNS configuration is correct"
   fi
   ```

5. **Use proper error handling**
   ```bash
   if ! execute_simple "command" "description"; then
       log_message "ERROR" "Failed to execute command"
       return 1
   fi
   ```

6. **Follow the existing function naming convention**
   - `step_*()` for main installation steps
   - `configure_*()` for configuration functions
   - `install_*()` for installation functions
   - `validate_*()` for validation functions

#### Documentation Standards

1. **Function documentation**
   ```bash
   # Function: install_postgresql_database
   # Purpose: Installs and configures PostgreSQL database for Odoo
   # Parameters: None
   # Returns: 0 on success, 1 on failure
   install_postgresql_database() {
       # Implementation
   }
   ```

2. **Update README.md for new features**
   - Add feature descriptions
   - Update installation instructions
   - Include troubleshooting information

3. **Update TECHNICAL_DOCS.md for technical changes**
   - Document new functions
   - Explain architectural changes
   - Update configuration examples

### Submitting Changes

#### Commit Message Guidelines

Use clear and descriptive commit messages:

```bash
# Good commit messages
git commit -m "Add Let's Encrypt SSL certificate support"
git commit -m "Fix DNS validation for subdomains"
git commit -m "Improve error handling in PostgreSQL installation"

# Bad commit messages
git commit -m "Fix bug"
git commit -m "Update script"
git commit -m "Changes"
```

#### Pull Request Process

1. **Ensure your code follows the style guidelines**
2. **Update documentation if needed**
3. **Test your changes thoroughly**
4. **Create a pull request with a clear description**

**Pull Request Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tested on clean Ubuntu 22.04
- [ ] Tested domain-based installation
- [ ] Tested IP-based installation
- [ ] Tested SSL certificate generation
- [ ] Tested error scenarios

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
```

### Feature Development

#### Adding New Features

1. **Discuss the feature first**
   - Open an issue to discuss the feature
   - Get feedback from maintainers
   - Ensure it aligns with project goals

2. **Follow the modular architecture**
   - Create dedicated functions for new features
   - Follow the existing error handling patterns
   - Add appropriate logging

3. **Update configuration options**
   - Add new variables if needed
   - Update user prompts
   - Maintain backward compatibility

#### Example: Adding a New Feature

```bash
# 1. Add configuration variable
NEW_FEATURE_ENABLED="false"

# 2. Add user prompt
configure_new_feature() {
    echo -e "${BOLD}${WHITE}Enable new feature? [y/N]: ${NC}"
    read -r enable_feature
    case "$enable_feature" in
        [Yy]|[Yy][Ee][Ss])
            NEW_FEATURE_ENABLED="true"
            ;;
        *)
            NEW_FEATURE_ENABLED="false"
            ;;
    esac
}

# 3. Add installation function
install_new_feature() {
    if [ "$NEW_FEATURE_ENABLED" = "true" ]; then
        show_step_header 9 "New Feature Installation" "Installing and configuring new feature"
        
        if execute_simple "feature_command" "Installing new feature"; then
            log_message "INFO" "New feature installed successfully"
        else
            log_message "ERROR" "Failed to install new feature"
            return 1
        fi
    fi
}

# 4. Add to main execution flow
main_installation() {
    # ... existing steps ...
    install_new_feature
    # ... rest of installation ...
}
```

### Testing New Features

#### Unit Testing

Create test functions for individual components:

```bash
# test_functions.sh
test_domain_validation() {
    local test_domain="example.com"
    if validate_domain_format "$test_domain"; then
        echo "✓ Domain validation test passed"
    else
        echo "✗ Domain validation test failed"
        return 1
    fi
}

test_ssl_certificate_generation() {
    # Test SSL certificate generation
    # Verify certificate files are created
    # Check certificate validity
}
```

#### Integration Testing

Test complete installation scenarios:

```bash
# integration_tests.sh
test_full_installation_with_domain() {
    # Set up test environment
    # Run installer with domain configuration
    # Verify all services are running
    # Test web interface accessibility
}

test_full_installation_without_domain() {
    # Set up test environment
    # Run installer without domain
    # Verify IP-based access works
    # Test self-signed SSL
}
```

### Documentation Guidelines

#### README.md Updates

When adding new features, update:
- Feature list
- Installation instructions
- Configuration options
- Troubleshooting section

#### Technical Documentation

Update TECHNICAL_DOCS.md with:
- New function descriptions
- Architecture changes
- Configuration file changes
- Security considerations

### Release Process

#### Version Numbering

We use semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes (backward compatible)

#### Release Checklist

1. **Update version numbers**
   ```bash
   SCRIPT_VERSION="2.2.0"
   ```

2. **Update documentation**
   - README.md
   - TECHNICAL_DOCS.md
   - CHANGELOG.md

3. **Test thoroughly**
   - All supported Odoo versions
   - Different installation scenarios
   - Error handling

4. **Create release**
   - Tag the release
   - Update website
   - Announce changes

### Getting Help

#### Communication Channels

- **GitHub Issues**: For bug reports and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Pull Request Reviews**: For code-related discussions

#### Maintainer Response Times

- **Bug reports**: Within 48 hours
- **Feature requests**: Within 1 week
- **Pull requests**: Within 1 week

### Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to Enhanced Odoo Installer! 🎉

