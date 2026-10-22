# Nginx PHP Version Updater

A lightweight, zero-dependency Bash utility designed for Linux VPS environments to audit and automatically update deprecated PHP version references in Nginx configuration files.

It scans server block configurations for PHP FastCGI/socket references lower than a target version (default: **PHP 8.2**) and upgrades them in place safely.

---

## Features

- **Safe Dry-Run Mode**: Inspect affected configuration files and preview changes without modifying anything on disk.
- **In-Place Updates**: Replaces obsolete PHP versions (e.g., `php7.4`, `php8.0`, `php8.1`) with the target version (`php8.2`).
- **Semantic Version Comparison**: Handles major and minor version checks accurately using built-in string comparison logic.
- **Automatic Syntax Validation**: Automatically executes `nginx -t` after updates to ensure server configuration integrity before reloading services.
- **Permission Safety**: Enforces root/sudo requirement specifically for fix operations.

---

## Prerequisites

- **OS**: Linux VPS (Ubuntu, Debian, or similar distribution using standard Nginx directory structures).
- **Web Server**: Nginx installed with sites located at `/etc/nginx/sites-enabled`.
- **Privileges**: `sudo` or `root` access (required for applying fixes and testing Nginx syntax).
- **Dependencies**: Standard POSIX tools (`bash`, `awk`, `grep`, `mktemp`). No external packages required.

---

## Installation

1. Save the script to your VPS (e.g., `/usr/local/bin/update-nginx-php` or within your maintenance scripts directory):

   ```bash
   sudo curl -sSL <your-repo-or-script-url> -o /usr/local/bin/update-nginx-php
