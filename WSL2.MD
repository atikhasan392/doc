# 🐧 WSL2 Ubuntu 24.04 Development Environment Setup

This guide sets up a modern PHP/Laravel development environment using WSL2 with Ubuntu 24.04.

Installed Stack:

- PHP 8.5
- Composer
- Node.js 24 (via NVM)
- MySQL 8.4 LTS
- Git & GitHub CLI

Designed for Laravel 12 / Livewire / Filament development.

---

## 1. Enable WSL2 & Install Ubuntu 24.04

```bash
wsl --install
wsl --list --online
wsl --install -d Ubuntu-24.04
```

---

## 2. Update System & Install Base Utilities

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y \
  software-properties-common \
  ca-certificates \
  curl \
  wget \
  gnupg \
  lsb-release \
  unzip \
  zip \
  build-essential \
  pkg-config
```

---

## 3. Install PHP 8.4 & Required Extensions

```bash
# Add the ondrej/php repository.
sudo apt update
sudo apt install -y software-properties-common
sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install PHP.
sudo apt install -y php8.4

# Install php extension.
sudo apt install -y \
php8.4 php8.4-cli php8.4-dev php8.4-readline php8.4-bcmath \
php8.4-curl php8.4-gd php8.4-intl php8.4-mbstring php8.4-mysql php8.4-opcache \
php8.4-redis php8.4-sqlite3 php8.4-xml php8.4-zip

php -v
php -m | grep -E "bcmath|curl|dom|gd|intl|mbstring|mysqli|pdo_mysql|pcntl|redis|sqlite3|xml|zip|Zend OPcache"
```

---

## 4. Install Composer (Global)

```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
EXPECTED_CHECKSUM=$(curl -s https://composer.github.io/installer.sig)
php -r "if (hash_file('sha384', 'composer-setup.php') === '$EXPECTED_CHECKSUM') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
php -r "unlink('composer-setup.php');"

composer -V
```

---

## 5. Install Node.js via NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

nvm install 24
nvm alias default 24
nvm use 24

node -v
npm -v
```

---

## 6. Install MySQL 8.4 LTS

```bash
wget https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.36-1_all.deb

sudo apt update
sudo apt install -y mysql-server
sudo systemctl enable --now mysql

mysql --version
```

Access MySQL:

```bash
sudo mysql
```

Inside MySQL:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
FLUSH PRIVILEGES;
EXIT;
```

Restart MySQL:

```bash
sudo systemctl restart mysql
```

Test connection:

```bash
sudo mysql -u root
```

---

## 7. Install Git & GitHub CLI

```bash
sudo apt update
sudo apt install -y git gh

# Configure Git
git config --global user.name "ATik HaSan"
git config --global user.email "me@atikhasan.com"

# Authenticate GitHub CLI
gh auth login
```

---

## 8. Laravel Install

```bash
composer global require laravel/installer

echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

laravel
```

