# WSL2 Ubuntu 24.04 Development Environment Setup for Laravel / PHP (PHP 8.5, Node 24, MySQL 8.4)

This guide sets up a modern PHP/Laravel development environment using WSL2 with Ubuntu 24.04.

Installed Stack:

- PHP 8.5
- Composer
- Node.js 24 (via NVM)
- MySQL 8.4 LTS
- Git & GitHub CLI

Designed for Laravel 12 / Livewire / Filament development.

## 1. Enable WSL2 & Install Ubuntu 24.04

```bash
wsl --install
wsl --list --online
wsl --install -d Ubuntu-24.04
```

## 2. Update System & Install Base Utilities

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common ca-certificates curl gnupg lsb-release unzip
```

## 3. Install PHP 8.5 & Required Extensions

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y
sudo apt update

# Install PHP.
sudo apt install -y php8.5

# Install required PHP extensions
sudo apt install -y \
  php8.5-cli php8.5-common php8.5-readline \
  php8.5-bcmath php8.5-curl php8.5-gd php8.5-mbstring php8.5-mysql \
  php8.5-xml php8.5-zip php8.5-intl php8.5-redis php8.5-sqlite3

# Verify extensions
php -m | grep -E "bcmath|curl|dom|gd|mbstring|mysqli|mysqlnd|PDO|pdo_mysql|xml|zip|intl|redis|sqlite3|pcntl|Zend OPcache"

# Verify install:
php -v
```

## 4. Install Composer (Global)

```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'c8b085408188070d5f52bcfe4ecfbee5f727afa458b2573b8eaaf77b3419b0bf2768dc67c86944da1544f06fa544fd47') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
php -r "unlink('composer-setup.php');"

# Verify install:
composer -V
```

## 5. Install Node.js via NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 24

# Verify install:
node -v
npm -v
```

## 6. Install latest MySQL (8.4 LTS)

```bash
wget https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.36-1_all.deb

# Select:
# MySQL Server & Cluster -> mysql-8.4-lts

sudo apt update
sudo apt install -y mysql-server
sudo systemctl enable --now mysql

# Access MySQL:
sudo mysql

# Inside MySQL:
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
FLUSH PRIVILEGES;
EXIT;

# Restart MySQL:
sudo systemctl restart mysql

# Verify install:
mysql --version
```

## 6. Install Git & GitHub CLI

```bash
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update
sudo apt install -y git gh

# Configure Git:
git config --global user.name "ATik HaSan"
git config --global user.email "me@atikhasan.com"

# Authenticate GitHub CLI:
gh auth login
```

## 7. Laravel install

```bash
composer global require laravel/installer

echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.profile
source ~/.profile

# Verify install:
laravel --version
```
