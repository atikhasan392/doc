# Laravel Development Environment Setup

## Ubuntu / WSL2 — Local Development Only

> ⚠️ **Local-only warning**
>
> This setup is designed strictly for a local development machine or WSL2 environment.
> Do **not** use this configuration on production servers.
>
> This guide intentionally enables developer-friendly settings such as verbose PHP errors, passwordless local MySQL root access, and phpMyAdmin auto-login. These are unsafe outside an isolated local environment.

---

## Stack Overview

| Tool               | Version / Channel  | Purpose                                            |
| ------------------ | ------------------ | -------------------------------------------------- |
| WSL 2              | Latest stable      | Linux virtualization layer for Windows development |
| Ubuntu             | Current LTS        | Linux development environment                      |
| PHP                | 8.5 NTS, FPM + CLI | Laravel backend runtime                            |
| Composer           | Latest stable      | PHP dependency manager                             |
| Laravel Installer  | Latest stable      | Laravel project scaffolding                        |
| MySQL              | 8.4 LTS            | Relational database                                |
| Redis              | Latest stable      | Cache, session, broadcast, and queue backend       |
| Node.js            | 24 LTS             | Frontend build tooling                             |
| Bun                | Latest stable      | JavaScript runtime and package manager             |
| Apache HTTP Server | 2.4                | Local web server with PHP-FPM                      |
| phpMyAdmin         | Latest stable      | Local database administration UI                   |
| GitHub CLI         | Latest stable      | GitHub authentication and workflow tooling         |

---

## Before You Start

### Assumptions

* You are using a fresh Ubuntu or WSL2 Ubuntu installation.
* You have `sudo` access.
* You are setting this up for Laravel development only.
* Replace placeholder values before running commands.

---

## Step 0 — Install Ubuntu on WSL2

Skip this step if you are already using native Ubuntu.

Run these commands from **PowerShell**:

```bash
wsl --install
wsl --list --online
wsl --install -d Ubuntu-26.04
```

Optional reset command:

```bash
wsl --unregister Ubuntu-26.04
```

> ⚠️ The reset command permanently deletes the selected WSL distribution, including files inside it.

---

## Step 1 — Update System and Install Base Packages

```bash
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

sudo apt install -y \
  curl wget gnupg ca-certificates lsb-release \
  apt-transport-https software-properties-common \
  zip unzip git build-essential
```

---

## Step 2 — Install PHP 8.5 NTS

```bash
sudo apt update

sudo apt install -y \
  php8.5 php8.5-fpm php8.5-cli \
  php8.5-common \
  php8.5-bcmath php8.5-curl php8.5-xml php8.5-gd \
  php8.5-mbstring php8.5-mysql php8.5-zip \
  php8.5-intl php8.5-readline \
  php8.5-redis php8.5-msgpack php8.5-igbinary \
  php8.5-sqlite3 php8.5-pgsql

php -v
php -m | grep -E "Zend OPcache|bcmath|curl|gd|intl|mbstring|mysqli|mysqlnd|pdo_mysql|redis|zip"

sudo systemctl enable --now php8.5-fpm
systemctl status php8.5-fpm --no-pager
```

---

## Step 3 — Configure PHP for Local Development

```bash
PHP_VERSION="8.5"

for PHP_INI in /etc/php/${PHP_VERSION}/cli/php.ini /etc/php/${PHP_VERSION}/fpm/php.ini; do
  [ -f "$PHP_INI" ] || continue

  sudo cp "$PHP_INI" "$PHP_INI.bak.$(date +%F-%H%M%S)"

  sudo sed -i \
    -e 's|^;*[[:space:]]*memory_limit[[:space:]]*=.*|memory_limit = 1024M|' \
    -e 's|^;*[[:space:]]*max_execution_time[[:space:]]*=.*|max_execution_time = 300|' \
    -e 's|^;*[[:space:]]*max_input_time[[:space:]]*=.*|max_input_time = 300|' \
    -e 's|^;*[[:space:]]*upload_max_filesize[[:space:]]*=.*|upload_max_filesize = 5120M|' \
    -e 's|^;*[[:space:]]*post_max_size[[:space:]]*=.*|post_max_size = 5120M|' \
    -e 's|^;*[[:space:]]*max_input_vars[[:space:]]*=.*|max_input_vars = 5000|' \
    -e 's|^;*[[:space:]]*date\.timezone[[:space:]]*=.*|date.timezone = Asia/Dhaka|' \
    -e 's|^;*[[:space:]]*display_errors[[:space:]]*=.*|display_errors = On|' \
    -e 's|^;*[[:space:]]*display_startup_errors[[:space:]]*=.*|display_startup_errors = On|' \
    -e 's|^;*[[:space:]]*log_errors[[:space:]]*=.*|log_errors = On|' \
    -e 's|^;*[[:space:]]*error_reporting[[:space:]]*=.*|error_reporting = E_ALL|' \
    -e 's|^;*[[:space:]]*max_file_uploads[[:space:]]*=.*|max_file_uploads = 100|' \
    -e 's|^;*[[:space:]]*realpath_cache_size[[:space:]]*=.*|realpath_cache_size = 32M|' \
    -e 's|^;*[[:space:]]*realpath_cache_ttl[[:space:]]*=.*|realpath_cache_ttl = 120|' \
    "$PHP_INI"

  echo "Updated: $PHP_INI"
done
```

### Configure OPcache

```bash
PHP_VERSION="8.5"

for OPCACHE_INI in /etc/php/${PHP_VERSION}/cli/conf.d/10-opcache.ini /etc/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini; do
  [ -f "$OPCACHE_INI" ] || continue

  sudo cp "$OPCACHE_INI" "$OPCACHE_INI.bak.$(date +%F-%H%M%S)"

  sudo sed -i \
    -e 's|^;*[[:space:]]*opcache.enable[[:space:]]*=.*|opcache.enable=1|' \
    -e 's|^;*[[:space:]]*opcache.enable_cli[[:space:]]*=.*|opcache.enable_cli=1|' \
    -e 's|^;*[[:space:]]*opcache.memory_consumption[[:space:]]*=.*|opcache.memory_consumption=256|' \
    -e 's|^;*[[:space:]]*opcache.interned_strings_buffer[[:space:]]*=.*|opcache.interned_strings_buffer=32|' \
    -e 's|^;*[[:space:]]*opcache.max_accelerated_files[[:space:]]*=.*|opcache.max_accelerated_files=50000|' \
    -e 's|^;*[[:space:]]*opcache.validate_timestamps[[:space:]]*=.*|opcache.validate_timestamps=1|' \
    -e 's|^;*[[:space:]]*opcache.revalidate_freq[[:space:]]*=.*|opcache.revalidate_freq=0|' \
    -e 's|^;*[[:space:]]*opcache.save_comments[[:space:]]*=.*|opcache.save_comments=1|' \
    "$OPCACHE_INI"

  echo "Updated: $OPCACHE_INI"
done

sudo systemctl restart php${PHP_VERSION}-fpm
```

### Verify PHP Configuration

```bash
echo "PHP Version:"
php -v

echo "PHP Settings:"
php -i | grep -E "memory_limit|upload_max_filesize|post_max_size|max_input_vars|date.timezone|display_errors|display_startup_errors|log_errors|error_reporting|max_file_uploads|realpath_cache_size|realpath_cache_ttl|opcache.enable|opcache.enable_cli|opcache.memory_consumption|opcache.interned_strings_buffer|opcache.max_accelerated_files|opcache.validate_timestamps|opcache.revalidate_freq|opcache.save_comments"

echo "PHP-FPM Status:"
systemctl status php${PHP_VERSION}-fpm --no-pager
```

### Recommended PHP Development Values

| Directive                         | Recommended value | Notes                                                     |
| --------------------------------- | ----------------- | --------------------------------------------------------- |
| `memory_limit`                    | `1024M`           | Useful for Composer, large imports, and dev tooling       |
| `max_execution_time`              | `300`             | Prevents premature timeout during local tasks             |
| `max_input_time`                  | `300`             | Useful for large form/file input                          |
| `upload_max_filesize`             | `5120M`           | Local-only high upload limit                              |
| `post_max_size`                   | `5120M`           | Must be equal to or higher than upload needs              |
| `max_input_vars`                  | `5000`            | Helps large admin forms, Filament forms, and nested input |
| `date.timezone`                   | `Asia/Dhaka`      | Match local timezone                                      |
| `display_errors`                  | `On`              | Local debugging only                                      |
| `display_startup_errors`          | `On`              | Local debugging only                                      |
| `log_errors`                      | `On`              | Keep logs enabled                                         |
| `error_reporting`                 | `E_ALL`           | Show all development errors                               |
| `max_file_uploads`                | `100`             | Useful for bulk uploads                                   |
| `realpath_cache_size`             | `32M`             | Improves path lookup performance                          |
| `realpath_cache_ttl`              | `120`             | Good default for development                              |
| `opcache.enable`                  | `1`               | Enable OPcache for FPM                                    |
| `opcache.enable_cli`              | `1`               | Useful for CLI tooling                                    |
| `opcache.memory_consumption`      | `256`             | Reasonable local allocation                               |
| `opcache.interned_strings_buffer` | `32`              | Better for framework-heavy apps                           |
| `opcache.max_accelerated_files`   | `50000`           | Suitable for Laravel/vendor-heavy projects                |
| `opcache.validate_timestamps`     | `1`               | Required for development file changes                     |
| `opcache.revalidate_freq`         | `0`               | Immediate file change detection                           |
| `opcache.save_comments`           | `1`               | Required by many PHP frameworks and packages              |

---

## Step 4 — Install Composer

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

## Step 5 — Install Laravel Installer

```bash
composer global require laravel/installer

grep -qxF 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' ~/.bashrc || \
  echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc

source ~/.bashrc

laravel --version
```

---

## Step 6 — Install Node.js 24 with NVM

NVM keeps Node.js isolated from the operating system package manager and makes upgrades or version switching cleaner.

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

nvm install 24
nvm use 24
nvm alias default 24

corepack enable

node -v
npm -v
yarn -v
pnpm -v

npm install -g npm npm-check-updates
```

---

## Step 7 — Install MySQL 8.4 LTS

MySQL Community Downloads Link - https://dev.mysql.com/downloads/repo/apt/

```bash
wget https://dev.mysql.com/get/mysql-apt-config_0.8.39-1_all.deb

echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.4-lts" \
  | sudo debconf-set-selections

sudo dpkg -i mysql-apt-config_0.8.36-1_all.deb
rm mysql-apt-config_0.8.36-1_all.deb

sudo apt update
sudo apt install -y mysql-server mysql-client

sudo systemctl enable --now mysql
systemctl status mysql --no-pager
```

---

## Step 8 — Configure Passwordless MySQL Root Access

> ⚠️ **Local development only**
>
> Passwordless root access is convenient, but it is a bad habit outside local development.
> Never use this on shared, public, staging, or production servers.

MySQL 8.4 disables `mysql_native_password` by default. Enable it before switching the local root user to passwordless authentication.

```bash
echo -e "\n# Local development only: enable legacy auth plugin for passwordless root access\nmysql_native_password=ON" \
  | sudo tee -a /etc/mysql/mysql.conf.d/mysqld.cnf

sudo systemctl restart mysql
```

Open MySQL shell:

```bash
sudo mysql
```

Run:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
FLUSH PRIVILEGES;
EXIT;
```

Verify:

```bash
mysql -u root -e "SELECT VERSION();"
```

---

## Step 9 — Install Redis

Ubuntu’s bundled Redis package may lag behind the latest stable Redis release. This setup uses the official Redis package repository.

```bash
curl -fsSL https://packages.redis.io/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/redis.list

sudo apt update
sudo apt install -y redis

sudo sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf
sudo sed -i 's/^protected-mode no/protected-mode yes/' /etc/redis/redis.conf

sudo systemctl enable --now redis-server
redis-cli ping
```

Expected output:

```text
PONG
```

---

## Step 10 — Install Apache and Connect PHP-FPM

Apache works as the HTTP front end. PHP requests are passed to PHP-FPM.

```bash
sudo apt install -y apache2

sudo a2enmod rewrite proxy_fcgi setenvif headers
sudo a2enconf php8.5-fpm

sudo systemctl restart apache2
systemctl status apache2 --no-pager
```

---

## Step 11 — Install phpMyAdmin

```bash
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" \
  | sudo debconf-set-selections

sudo apt install -y phpmyadmin
```

### Enable phpMyAdmin Auto-Login

> ⚠️ **Local development only**
>
> This stores database credentials in plain text. Do not use this on any server exposed to other users or the internet.

```bash
sudo tee /etc/phpmyadmin/conf.d/99-autologin.php > /dev/null <<'EOF'
<?php
$cfg['Servers'][1]['auth_type']       = 'config';
$cfg['Servers'][1]['user']            = 'root';
$cfg['Servers'][1]['password']        = '';
$cfg['Servers'][1]['AllowNoPassword'] = true;
EOF
```

Open phpMyAdmin:

```text
http://localhost/phpmyadmin
```

---

## Step 12 — Install GitHub CLI

```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list

sudo apt update
sudo apt install -y gh

gh auth login
```

Configure Git identity:

```bash
git config --global user.name "<YOUR_GIT_NAME>"
git config --global user.email "<YOUR_GIT_EMAIL>"
```

---

## Step 13 — Install Visual Studio Code CLI

```bash
code .
```

---

## Step 14 — Configure Shell History

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

## Step 15 — Final Verification Checklist

Run these commands after installation:

```bash
php -v
composer --version
laravel --version
node -v
npm -v
yarn -v
bun --version
mysql -u root -e "SELECT VERSION();"
redis-cli ping
apache2 -v
gh --version
```

Expected results:

| Tool              | Expected status             |
| ----------------- | --------------------------- |
| PHP 8.5           | Installed                   |
| PHP-FPM           | Active                      |
| Composer          | Installed                   |
| Laravel Installer | Installed                   |
| MySQL 8.4         | Active                      |
| Redis             | Responds with `PONG`        |
| Node.js 24        | Active default version      |
| NPM               | Installed                   |
| Yarn              | Installed                   |
| Bun               | Installed                   |
| Apache 2.4        | Active                      |
| phpMyAdmin        | Available at `/phpmyadmin`  |
| GitHub CLI        | Installed and authenticated |

---

## Maintenance Notes

### Update system packages

```bash
# Update ubuntu
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

# Update Composer packages globally
composer global update

# Update global NPM packages
npm update -g

# Check running services
systemctl status php8.5-fpm --no-pager
systemctl status mysql --no-pager
systemctl status redis-server --no-pager
systemctl status apache2 --no-pager
```

## Production Reminder

Do not copy this setup directly to production.

For production, you must change at minimum:

* Disable `display_errors` and `display_startup_errors`.
* Use strong MySQL passwords and least-privilege database users.
* Remove phpMyAdmin auto-login.
* Restrict database and Redis network access.
* Harden Apache virtual hosts and headers.
* Configure TLS.
* Configure backups, monitoring, logs, and firewall rules.
* Use deployment-specific PHP-FPM and OPcache settings.
