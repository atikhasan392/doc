# Laravel Development Environment Setup (Ubuntu 24.04 / WSL2)

This guide provides a **fully manual, copy-paste friendly version** of your setup script.
Each step is broken down with **clear explanations** so you understand what is happening instead of blindly running a script.

> ⚠️ This is strictly for **local development environments only**.
> Do NOT use this on production servers.

---

## 🧠 Overview

This setup installs:

- PHP 8.5 (FPM-based)
- Composer + Laravel installer
- MySQL 8.4 (secure local config)
- Redis (latest official repo)
- Node.js 24 (via NVM)
- Bun runtime
- Apache with PHP-FPM
- phpMyAdmin (auto-login for dev)
- Git + GitHub CLI

---

## ⚠️ Before You Start

- You must run commands with `sudo`
- This assumes a **fresh Ubuntu 24.04 / WSL2 environment**
- Replace `<YOUR_USERNAME>` where needed

---

# 1️⃣ System Update & Base Packages

### Why?

Ensures your system is up-to-date and installs essential tools.

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

sudo apt install -y \
  curl wget gnupg ca-certificates lsb-release \
  apt-transport-https software-properties-common \
  unzip git build-essential
```

---

# 2️⃣ Install PHP 8.5 (Ondřej PPA)

### Why?

Ubuntu default PHP is outdated. This PPA provides latest stable PHP.

```bash
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
```

### Install PHP + Extensions (Laravel-ready)

```bash
sudo apt install -y \
  php8.5 php8.5-fpm php8.5-cli \
  php8.5-bcmath php8.5-curl php8.5-dom php8.5-gd \
  php8.5-mbstring php8.5-mysql php8.5-xml php8.5-zip \
  php8.5-intl php8.5-readline php8.5-redis \
  php8.5-msgpack php8.5-igbinary php8.5-sqlite3 \
  php8.5-pgsql php8.5-sqlsrv
```

### Enable PHP-FPM

```bash
sudo systemctl enable --now php8.5-fpm
```

---

# 3️⃣ Install Composer (Global)

### Why?

Composer is required for Laravel dependency management.

```bash
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
rm composer-setup.php
```

---

# 4️⃣ Install Laravel Installer (User Level)

### Why?

Allows you to create projects using `laravel new project-name`

```bash
composer global require laravel/installer
```

### Add Composer global bin to PATH

```bash
echo 'export PATH="$PATH:$HOME/.config/composer/vendor/bin"' >> ~/.bashrc
source ~/.bashrc
```

---

# 5️⃣ Install Node.js 24 via NVM

### Why?

Avoid system Node conflicts and manage versions cleanly.

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
```

```bash
nvm install 24
nvm use 24
nvm alias default 24
```

### Install global tools

```bash
npm install -g npm yarn npm-check-updates
```

---

# 6️⃣ Install Bun Runtime

### Why?

Fast JS runtime and package manager alternative.

```bash
curl -fsSL https://bun.sh/install | bash
```

---

# 7️⃣ Install MySQL 8.4 (LTS)

### Why?

Latest stable MySQL with long-term support.

```bash
wget https://dev.mysql.com/get/mysql-apt-config_0.8.36-1_all.deb
```

```bash
echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.4-lts" | sudo debconf-set-selections
sudo dpkg -i mysql-apt-config_0.8.36-1_all.deb
```

```bash
sudo apt update
sudo apt install -y mysql-server mysql-client
```

### Start MySQL

```bash
sudo systemctl enable --now mysql
```

### Create user (replace username/password)

```bash
sudo mysql
```

```sql
CREATE USER 'your_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON *.* TO 'your_user'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
```

---

# 8️⃣ Install Redis (Latest Official Repo)

### Why?

Ubuntu repo Redis is outdated.

```bash
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
```

```bash
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
```

```bash
sudo apt update
sudo apt install -y redis
```

### Secure Redis (local only)

```bash
sudo sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf
sudo sed -i 's/^protected-mode no/protected-mode yes/' /etc/redis/redis.conf
```

```bash
sudo systemctl enable --now redis-server
```

### Test

```bash
redis-cli ping
```

---

# 9️⃣ Install Apache + PHP-FPM

### Why?

Apache acts as web server, PHP handled via FPM.

```bash
sudo apt install -y apache2
```

```bash
sudo a2enmod rewrite proxy_fcgi setenvif headers
sudo a2enconf php8.5-fpm
sudo systemctl restart apache2
```

---

# 🔟 Install phpMyAdmin (Auto Login - DEV ONLY)

### ⚠️ WARNING

Stores password in plain text.

```bash
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
sudo apt install -y phpmyadmin
```

### Enable auto login

```bash
sudo nano /etc/phpmyadmin/conf.d/99-autologin.php
```

Paste:

```php
<?php
$cfg['Servers'][1]['auth_type'] = 'config';
$cfg['Servers'][1]['user'] = 'your_user';
$cfg['Servers'][1]['password'] = 'your_password';
$cfg['Servers'][1]['AllowNoPassword'] = false;
```

---

# 1️⃣1️⃣ Install GitHub CLI

```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
```

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
```

```bash
sudo apt update
sudo apt install -y gh
```

---

# ✅ Final Steps

```bash
source ~/.bashrc
```

```bash
laravel new my-project
cd my-project
php artisan serve
```

---

# 🎯 Summary

| Tool        | Status |
| ----------- | ------ |
| PHP 8.5     | ✅     |
| Composer    | ✅     |
| Laravel CLI | ✅     |
| MySQL 8.4   | ✅     |
| Redis       | ✅     |
| Node 24     | ✅     |
| Bun         | ✅     |
| Apache      | ✅     |

---

# 💡 Brutal Truth

If you don’t understand each step here, you WILL struggle debugging later.

Don’t just copy-paste. Break things. Fix them. That’s how you actually learn.
