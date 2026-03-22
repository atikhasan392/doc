# Laravel Development Environment Setup

### Ubuntu 24.04 / WSL2 — Local Only

> **Warning:** This guide is strictly for **local development** environments.
> Do **not** apply this configuration to production servers.

---

## Stack Overview

| Tool        | Version   | Purpose                           |
| ----------- | --------- | --------------------------------- |
| PHP         | 8.4 (FPM) | Runtime                           |
| Composer    | Latest    | PHP dependency manager            |
| Laravel CLI | Latest    | Project scaffolding               |
| MySQL       | 8.4 LTS   | Primary database                  |
| Redis       | Latest    | Cache / queue driver              |
| Node.js     | 24 (NVM)  | Frontend tooling                  |
| Bun         | Latest    | Fast JS runtime & package manager |
| Apache      | 2.4       | Web server (PHP-FPM proxy)        |
| phpMyAdmin  | Latest    | DB GUI (auto-login, dev only)     |
| GitHub CLI  | Latest    | Git + GitHub integration          |

---

## Prerequisites

- Fresh **Ubuntu 24.04** or **WSL2** instance
- `sudo` access
- Replace `<YOUR_USERNAME>` with your actual Linux username wherever it appears

---

## Step 0 — Enable WSL2 & Install Ubuntu 24.04

Run the following from **PowerShell (Windows)** — skip if already on native Ubuntu.

```bash
wsl --install
wsl --list --online
wsl --install -d Ubuntu-24.04
```

---

## Step 1 — System Update & Base Packages

```bash
# Refresh package index and upgrade existing packages
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

# Install essential build and utility tools
sudo apt install -y \
  curl wget gnupg ca-certificates lsb-release \
  apt-transport-https software-properties-common \
  unzip git build-essential
```

---

## Step 2 — PHP 8.4

Ubuntu's default PHP is outdated. The Ondřej PPA provides the latest stable release.

```bash
# Add the Ondřej PHP PPA
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install PHP 8.4 with all extensions required for Laravel
sudo apt install -y \
  php8.4 php8.4-fpm php8.4-cli \
  php8.4-bcmath php8.4-curl php8.4-dom php8.4-gd \
  php8.4-mbstring php8.4-mysql php8.4-xml php8.4-zip \
  php8.4-intl php8.4-readline php8.4-redis \
  php8.4-msgpack php8.4-igbinary php8.4-sqlite3 \
  php8.4-pgsql

# Enable and start PHP-FPM
sudo systemctl enable --now php8.4-fpm
```

---

## Step 3 — Composer

```bash
# Download the installer to a temp location
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php

# Verify the installer against the official checksum — abort if tampered
EXPECTED_SIG="$(curl -sS https://composer.github.io/installer.sig)"
ACTUAL_SIG="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"

if [ "$EXPECTED_SIG" != "$ACTUAL_SIG" ]; then
    echo "ERROR: Composer installer signature mismatch. Aborting."
    rm /tmp/composer-setup.php
    exit 1
fi

# Install Composer globally
sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm /tmp/composer-setup.php

# Confirm installation
composer --version
```

---

## Step 4 — Laravel Installer

```bash
# Install the Laravel CLI globally via Composer
composer global require laravel/installer

# Add Composer's global bin directory to PATH
echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Confirm the Laravel CLI is available
laravel --version
```

---

## Step 5 — Node.js 24 via NVM

NVM avoids system-level Node conflicts and allows clean version switching.

```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load NVM into current shell session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install Node.js 24 and set it as default
nvm install 24
nvm use 24
nvm alias default 24

# Install commonly used global npm packages
npm install -g npm yarn npm-check-updates
```

---

## Step 6 — Bun Runtime

```bash
# Install Bun — fast alternative to Node for running and bundling JS
curl -fsSL https://bun.sh/install | bash

# Reload shell so the `bun` command is available
source ~/.bashrc
```

---

## Step 7 — MySQL 8.4 LTS

```bash
# Download the official MySQL APT config package
wget https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb

# Pre-select MySQL 8.4 LTS before running the config package
echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.4-lts" \
  | sudo debconf-set-selections

# Register MySQL APT repository
sudo dpkg -i mysql-apt-config_0.8.36-1_all.deb
rm mysql-apt-config_0.8.36-1_all.deb
sudo apt update

# Install MySQL server and client
sudo apt install -y mysql-server mysql-client

# Enable and start MySQL
sudo systemctl enable --now mysql
```

### Configure Passwordless Root Access (Dev Only)

```bash
# Connect using the temporary auth socket
sudo mysql
```

```sql
-- Switch root to native password auth with an empty password
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
FLUSH PRIVILEGES;
EXIT;
```

```bash
# Confirm you can now connect without any password prompt
mysql -u root
```

---

## Step 8 — Redis

Ubuntu's packaged Redis is outdated. This installs from the official Redis repository.

```bash
# Import the Redis GPG key
curl -fsSL https://packages.redis.io/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

# Register the Redis APT repository
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] \
  https://packages.redis.io/deb $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt update
sudo apt install -y redis

# Restrict Redis to localhost only (no external exposure)
sudo sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf
sudo sed -i 's/^protected-mode no/protected-mode yes/' /etc/redis/redis.conf

# Enable, start, and test
sudo systemctl enable --now redis-server
redis-cli ping
# Expected output: PONG
```

---

## Step 9 — Apache + PHP-FPM

Apache serves as the HTTP front-end; PHP requests are proxied to PHP-FPM.

```bash
# Install Apache
sudo apt install -y apache2

# Enable required modules: URL rewriting, FPM proxy, env pass-through, headers
sudo a2enmod rewrite proxy_fcgi setenvif headers

# Enable the PHP-FPM configuration for Apache
sudo a2enconf php8.4-fpm

# Apply changes
sudo systemctl restart apache2
```

---

## Step 10 — phpMyAdmin (Auto-Login — Dev Only)

> **Warning:** The configuration below stores your database password in plain text.
> It is **only** acceptable in a local, isolated development environment.

```bash
# Tell the installer to configure Apache automatically
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" \
  | sudo debconf-set-selections

# Install phpMyAdmin
sudo apt install -y phpmyadmin
```

### Enable Auto-Login

```bash
sudo tee /etc/phpmyadmin/conf.d/99-autologin.php > /dev/null <<'EOF'
<?php
$cfg['Servers'][1]['auth_type']      = 'config';
$cfg['Servers'][1]['user']           = 'root';
$cfg['Servers'][1]['password']       = '';
$cfg['Servers'][1]['AllowNoPassword'] = true;
EOF
```

Access phpMyAdmin at: **http://localhost/phpmyadmin**

---

## Step 11 — GitHub CLI

```bash
# Import the GitHub CLI GPG key
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg

# Register the GitHub CLI APT repository
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list

sudo apt update
sudo apt install -y gh

# Authenticate with GitHub
gh auth login
```

```bash
# Configure Git:
git config --global user.name "ATik HaSan"
git config --global user.email "me@atikhasan.com"
```

---

## Step 12 — Shell History Configuration

```bash
# Append history settings to .bashrc
cat >> ~/.bashrc <<'EOF'

# ── Shell History ────────────────────────────────────────────────
export HISTFILE=~/.bash_history   # Persist history across sessions
export HISTSIZE=10000             # Max commands kept in memory
export HISTFILESIZE=0             # Disable on-disk history persistence
EOF

source ~/.bashrc
```

---

## Final Verification

```bash
# Reload shell environment
source ~/.bashrc

# Verify all tools are on PATH and reporting versions
php --version
composer --version
laravel --version
mysql --version
redis-cli --version
node --version
npm --version
bun --version
gh --version
```

### Create Your First Laravel Project

```bash
laravel new my-project
cd my-project
php artisan serve
```

Visit **http://127.0.0.1:8000** — your local Laravel environment is ready.

---

## Summary

| Tool        | Installed |
| ----------- | --------- |
| PHP 8.4     | ✅        |
| Composer    | ✅        |
| Laravel CLI | ✅        |
| MySQL 8.4   | ✅        |
| Redis       | ✅        |
| Node.js 24  | ✅        |
| NPM         | ✅        |
| Yarn        | ✅        |
| Bun         | ✅        |
| Apache      | ✅        |
| GitHub CLI  | ✅        |
