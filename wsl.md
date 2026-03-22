# Laravel Development Environment Setup

### Ubuntu 24.04 / WSL2 — Local Only

> **⚠️ Warning:** This guide is strictly for **local development** environments.
> Do **not** apply this configuration to production servers.

---

## Stack Overview

| Tool        | Version   | Purpose                           |
| ----------- | --------- | --------------------------------- |
| PHP         | 8.5 (FPM) | Runtime                           |
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

<!-- wsl --unregister Ubuntu-24.04 -->

---

## Step 1 — System Update & Base Packages

```bash
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

sudo apt install -y \
  curl wget gnupg ca-certificates lsb-release \
  apt-transport-https software-properties-common \
  unzip git build-essential
```

---

## Step 2 — PHP 8.5

Ubuntu's default PHP is outdated. The Ondřej PPA provides the latest stable release.

```bash
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

sudo apt install -y \
  php8.5 php8.5-fpm php8.5-cli \
  php8.5-bcmath php8.5-curl php8.5-dom php8.5-gd \
  php8.5-mbstring php8.5-mysql php8.5-xml php8.5-zip \
  php8.5-intl php8.5-readline php8.5-redis \
  php8.5-msgpack php8.5-igbinary php8.5-sqlite3 \
  php8.5-pgsql

sudo systemctl enable --now php8.5-fpm
```

### Configure php.ini for Development

```bash
for PHP_INI in /etc/php/8.5/cli/php.ini /etc/php/8.5/fpm/php.ini; do
  [ -f "$PHP_INI" ] || continue
  sudo sed -i \
    -e '/^;*\s*memory_limit/c\memory_limit = 1024M' \
    -e '/^;*\s*upload_max_filesize/c\upload_max_filesize = 5120M' \
    -e '/^;*\s*post_max_size/c\post_max_size = 5120M' \
    -e '/^;*\s*max_input_vars/c\max_input_vars = 3000' \
    -e '/^;*\s*date\.timezone/c\date.timezone = Asia/Dhaka' \
    -e '/^;*\s*display_errors/c\display_errors = On' \
    -e '/^;*\s*max_file_uploads/c\max_file_uploads = 100' \
    -e '/^;*\s*realpath_cache_size/c\realpath_cache_size = 16M' \
    "$PHP_INI" && echo "Updated: $PHP_INI"
done

sudo systemctl restart php8.5-fpm
php -i | grep -E "memory_limit|upload_max_filesize|post_max_size|date.timezone|display_errors"
```

#### php.ini Recommended Values

| Directive             | Default | Recommended |
| --------------------- | ------- | ----------- |
| `memory_limit`        | 128M    | 1024M       |
| `upload_max_filesize` | 2M      | 5120M       |
| `post_max_size`       | 8M      | 512M        |
| `max_input_vars`      | 1000    | 3000        |
| `date.timezone`       | UTC     | Asia/Dhaka  |
| `display_errors`      | Off     | On          |
| `max_file_uploads`    | 20      | 100         |
| `realpath_cache_size` | 4096K   | 16M         |

---

## Step 3 — Composer

```bash
curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php

EXPECTED_SIG="$(curl -sS https://composer.github.io/installer.sig)"
ACTUAL_SIG="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"

if [ "$EXPECTED_SIG" != "$ACTUAL_SIG" ]; then
    echo "ERROR: Composer installer signature mismatch. Aborting."
    rm /tmp/composer-setup.php
    exit 1
fi

sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm /tmp/composer-setup.php

composer --version
```

---

## Step 4 — Laravel Installer

```bash
composer global require laravel/installer

echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

laravel --version
```

---

## Step 5 — Node.js 24 via NVM

NVM avoids system-level Node conflicts and allows clean version switching.

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

nvm install 24
nvm use 24
nvm alias default 24

npm install -g npm yarn npm-check-updates
```

---

## Step 6 — Bun Runtime

```bash
curl -fsSL https://bun.sh/install | bash

source ~/.bashrc
```

---

## Step 7 — MySQL 8.4 LTS

```bash
wget https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb

echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.4-lts" \
  | sudo debconf-set-selections

sudo dpkg -i mysql-apt-config_0.8.36-1_all.deb
rm mysql-apt-config_0.8.36-1_all.deb
sudo apt update

sudo apt install -y mysql-server mysql-client

sudo systemctl enable --now mysql
```

### Configure Passwordless Root Access (Dev Only)

MySQL 8.4 ships with `mysql_native_password` **disabled** by default.
It must be explicitly enabled before switching root to use it.

```bash
echo -e "\n# Enable legacy auth plugin required for passwordless root access\nmysql_native_password=ON" \
  | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf

sudo systemctl restart mysql
```

```bash
sudo mysql
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
FLUSH PRIVILEGES;
EXIT;
```

```bash
mysql -u root
```

---

## Step 8 — Redis

Ubuntu's packaged Redis is outdated. This installs from the official Redis repository.

```bash
curl -fsSL https://packages.redis.io/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] \
  https://packages.redis.io/deb $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt update
sudo apt install -y redis

sudo sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf
sudo sed -i 's/^protected-mode no/protected-mode yes/' /etc/redis/redis.conf

sudo systemctl enable --now redis-server
redis-cli ping
```

Expected output: `PONG`

---

## Step 9 — Apache + PHP-FPM

Apache serves as the HTTP front-end; PHP requests are proxied to PHP-FPM.

```bash
sudo apt install -y apache2

sudo a2enmod rewrite proxy_fcgi setenvif headers

sudo a2enconf php8.5-fpm

sudo systemctl restart apache2
```

---

## Step 10 — phpMyAdmin (Auto-Login — Dev Only)

> **Warning:** The configuration below stores your database password in plain text.
> It is **only** acceptable in a local, isolated development environment.

```bash
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" \
  | sudo debconf-set-selections

sudo apt install -y phpmyadmin
```

### Enable Auto-Login

```bash
sudo tee /etc/phpmyadmin/conf.d/99-autologin.php > /dev/null <<'EOF'
<?php
$cfg['Servers'][1]['auth_type']       = 'config';
$cfg['Servers'][1]['user']            = 'root';
$cfg['Servers'][1]['password']        = '';
$cfg['Servers'][1]['AllowNoPassword'] = true;
EOF
```

Access phpMyAdmin at: **http://localhost/phpmyadmin**

---

## Step 11 — GitHub CLI

```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list

sudo apt update
sudo apt install -y gh

gh auth login
```

```bash
git config --global user.name "ATik HaSan"
git config --global user.email "me@atikhasan.com"
```

---

## Step 12 — Shell History Configuration

```bash
cat >> ~/.bashrc <<'EOF'

# Shell History
export HISTFILE=~/.bash_history
export HISTSIZE=10000
export HISTFILESIZE=0
EOF

source ~/.bashrc
```

---

## Summary

| Tool        | Installed |
| ----------- | --------- |
| PHP 8.5     | ✅        |
| Composer    | ✅        |
| Laravel CLI | ✅        |
| MySQL 8.4   | ✅        |
| Redis       | ✅        |
| Node.js 24  | ✅        |
| NPM         | ✅        |
| Yarn        | ✅        |
| Bun         | ✅        |
| Apache 2.4  | ✅        |
| phpMyAdmin  | ✅        |
| GitHub CLI  | ✅        |
