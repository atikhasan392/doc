# WSL 2 + Ubuntu 24.04 + Laravel Full Stack Development Setup

This document provides a **clean, production-like, and future-proof** setup for Laravel development on **Windows using WSL 2 with Ubuntu 24.04**. It covers PHP 8.4, Composer, Node.js, Bun, MySQL, Redis, Apache, phpMyAdmin, Git, and GitHub CLI.

The goal is not a "toy" setup, but a stack that mirrors real-world production closely while remaining developer-friendly.

---

## 0. WSL 2 Installation (From Windows)

```bash
wsl --install
wsl --list --online
wsl --install Ubuntu-24.04

sudo passwd root
```

After installation, restart Windows if prompted and complete the Ubuntu user setup.

---

## 1. System Update & Base Utilities

Update Ubuntu and install required base packages.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install libatomic1 -y
sudo apt install -y software-properties-common ca-certificates curl gnupg lsb-release unzip
```

---

## 2. PHP 8.4 Installation (Ondrej PPA)

Ubuntu does not ship PHP 8.4 by default. Ondrej’s PPA is the industry standard for modern PHP versions.

```bash
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php8.4
```

```bash
ora@Node:/etc/php/8.4/cli
sudo nano php.ini
```

### Required PHP Extensions (Laravel-Ready)

```bash
sudo apt install -y \
php8.4-bcmath php8.4-curl php8.4-dom php8.4-gd \
php8.4-mbstring php8.4-mysql php8.4-pdo-mysql \
php8.4-pdo-sqlite php8.4-xml php8.4-zip \
php8.4-mysqli php8.4-redis
```

### Extension Verification

```bash
php -m | grep -E "bcmath|ctype|curl|dom|fileinfo|gd|json|mbstring|openssl|pdo|pdo_mysql|pdo_sqlite|session|tokenizer|xml|zip|mysqli"
```

### Install PHP CLI

```bash
sudo apt install php8.4-intl
```

```bash
php -v
php --ini
php -m | grep -i intl
```

---

## 3. Composer (System-wide)

```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
php -r "unlink('composer-setup.php');"
```

```bash
composer -V
```

---

## 4. Node.js (Laravel Vite Compatible)

NVM is used to manage Node versions cleanly.

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 25
```

```bash
node -v
npm -v
```

---

## 5. Bun (Fast Frontend Tooling)

```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
bun -v
```

---

## 6. MySQL 8 Setup

```bash
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql
mysql --version
```

### Root Login for Local Development

This is strictly for local development. Do **not** replicate this in production.

```bash
sudo mysql
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
FLUSH PRIVILEGES;
EXIT;
```

```bash
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```

```ini
max_allowed_packet = 512M
```

```bash
sudo systemctl restart mysql
```

---

## 7. Apache 2 Installation

```bash
sudo apt install -y apache2
sudo a2enmod rewrite
sudo systemctl restart apache2
```

---

## 8. phpMyAdmin (Manual, PHP 8.4 Safe)

```bash
cd /var/www
sudo wget https://files.phpmyadmin.net/phpMyAdmin/5.2.3/phpMyAdmin-5.2.3-all-languages.tar.gz
sudo tar xzf phpMyAdmin-5.2.3-all-languages.tar.gz
sudo mv phpMyAdmin-5.2.3-all-languages phpmyadmin
sudo rm phpMyAdmin-5.2.3-all-languages.tar.gz
```

```bash
sudo mkdir -p /var/www/phpmyadmin/tmp
sudo chown -R www-data:www-data /var/www/phpmyadmin
sudo chmod 777 /var/www/phpmyadmin/tmp
```

### phpMyAdmin Configuration

```bash
cd /var/www/phpmyadmin
sudo cp config.sample.inc.php config.inc.php
sudo nano config.inc.php
```

```php
$cfg['blowfish_secret'] = 'oWUPyrWkeftLYPngBCM8iZILseVyx5eF';

$i = 0;
$i++;
$cfg['Servers'][$i]['auth_type'] = 'config';
$cfg['Servers'][$i]['host'] = '127.0.0.1';
$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = '';
$cfg['Servers'][$i]['AllowNoPassword'] = true;

$cfg['TempDir'] = '/var/www/phpmyadmin/tmp';
```

---

## 9. Apache VirtualHost (Laravel + phpMyAdmin)

```bash
sudo nano /etc/apache2/sites-available/000-default.conf
```

```apache
<VirtualHost *:80>
    ServerName localhost

    DocumentRoot /var/www/html

    Alias /phpmyadmin /var/www/phpmyadmin

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>

    <Directory /var/www/phpmyadmin>
        Options FollowSymLinks
        DirectoryIndex index.php
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
sudo systemctl reload apache2
```

- [Laravel 12](http://localhost)
- [phpMyAdmin](http://localhost/phpmyadmin)

---

## 10. Git (Latest) & GitHub CLI

```bash
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update
sudo apt install -y git gh
```

```bash
git config --global user.name "ATik HaSan"
git config --global user.email "atikhasan2700@gmail.com"
```

```bash
gh auth login
```

---

## 11. Redis (Laravel Cache / Queue)

```bash
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
sudo apt update
sudo apt install -y redis
```

```bash
redis-cli --version
```

---

## 12. Final Version Check

```bash
php -v
composer -V
node -v
npm -v
bun -v
mysql --version
git -v
redis-cli --version
```

---

## 13. Auto Terminal History Clear (Ubuntu 24.04 + Bash)

```bash
# Disable bash history (Ubuntu 24.04)
unset HISTFILE
export HISTSIZE=0
export HISTFILESIZE=0
export HISTCONTROL=ignorespace
set +o history

history -c
history -w
rm -f ~/.bash_history

trap 'history -c; history -w; rm -f ~/.bash_history' EXIT
```

```bash
source ~/.bashrc
exec bash
```

## Final Notes

- phpMyAdmin runs through Apache, not PHP’s built-in server
- Laravel uses the public directory as the Apache DocumentRoot
- All tooling versions are modern and upgrade-friendly
- This setup is designed to scale with real projects, not demos

---

If something breaks, the problem is not the stack — it’s your understanding of it.

