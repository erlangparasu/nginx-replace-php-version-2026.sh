# Nginx PHP Version Updater

A lightweight, zero-dependency Bash utility designed for Linux VPS environments to audit and automatically update deprecated PHP version references in Nginx configuration files.
It scans server block configurations for PHP FastCGI/socket references lower than a target version (default: PHP 8.2) and upgrades them in place safely.

## FEATURES

- Safe Dry-Run Mode: Inspect affected configuration files and preview changes without modifying anything on disk.

- In-Place Updates: Replaces obsolete PHP versions (e.g., php7.4, php8.0, php8.1) with the target version (php8.2).

- Semantic Version Comparison: Handles major and minor version checks accurately using built-in string comparison logic.

- Automatic Syntax Validation: Automatically executes "nginx -t" after updates to ensure server configuration integrity before reloading services.

- Permission Safety: Enforces root/sudo requirement specifically for fix operations.

## PREREQUISITES

- OS: Linux VPS (Ubuntu, Debian, or similar distribution using standard Nginx directory structures).

- Web Server: Nginx installed with sites located at /etc/nginx/sites-enabled.

- Privileges: sudo or root access (required for applying fixes and testing Nginx syntax).

- Dependencies: Standard POSIX tools (bash, awk, grep, mktemp). No external packages required.

## INSTALLATION

- Save the script to your VPS (e.g., /usr/local/bin/update-nginx-php or within your maintenance scripts directory):

- sudo curl -sSL  -o /usr/local/bin/update-nginx-php

- Grant execution permissions:

```bash
sudo chmod +x /usr/local/bin/update-nginx-php
```

## USAGE

```bash
update-nginx-php [--dry-run | --fix]
```

Options:

    --dry-run: (Standard User / Root) Scans configurations and prints files that require updates without making changes.

    --fix: (Root / sudo) Performs in-place replacements and validates Nginx configuration syntax.

QUICKSTART & WORKFLOW

    Run a Dry-Run (Recommended First Step)
    Always run a simulation first to inspect which Nginx site configurations contain outdated PHP references:

./update-nginx-php --dry-run
Example Output:
Nginx PHP Version Updater
Target Directory: /etc/nginx/sites-enabled
Target Threshold: PHP 8.2
Execution Mode:   dry-run

[MATCH] /etc/nginx/sites-enabled/example.com.conf -> php7.4 (< 8.2)
└─> [DRY-RUN] Would update /etc/nginx/sites-enabled/example.com.conf to php8.2

[KEEP]  /etc/nginx/sites-enabled/app.com.conf -> php8.3 (>= 8.2)
==================================================
Summary: 1 file(s) identified for update.

    Apply Updates
    Once verified, execute the script with root privileges to apply changes:

sudo ./update-nginx-php --fix

    Reload Nginx
    If the syntax check passes, reload the Nginx daemon to apply the changes to running sites:

sudo systemctl reload nginx

CONFIGURATION VARIABLES

If you need to change the target PHP version or site directory, modify the variables near the top of the script:

TARGET_DIR="/etc/nginx/sites-enabled"
TARGET_VERSION="8.2"

SAFETY & BEST PRACTICES

    Backups: Before running --fix in production environments, take a quick snapshot or back up your configuration directory:
    sudo cp -r /etc/nginx/sites-available /etc/nginx/sites-available.bak

    PHP-FPM Pool Installation: Ensure the target PHP-FPM service (e.g., php8.2-fpm) is installed and active on your VPS before updating Nginx sockets to avoid 502 Bad Gateway errors.

