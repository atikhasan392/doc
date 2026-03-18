# 🚀 Laravel 12 Full Stack Development Setup

Production-like local development environment using **WSL2 (Windows Subsystem for Linux 2)** with **Ubuntu 24.04**.

---

### 0. Enable WSL2 & Install Ubuntu 24.04

```powershell
wsl --install
wsl --list --online
wsl --install -d Ubuntu-24.04
```

Complete the Ubuntu user setup after installation.

---

### 1. Update System & Install Base Utilities

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y software-properties-common ca-certificates curl gnupg lsb-release unzip
```

---

### 2. Install PHP 8.5 & Required Extensions

Add PHP repository:

```bash
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
```

Install PHP:

```bash
sudo apt install -y php8.4 php8.4-cli
```

Install required extensions:

```bash
sudo apt install -y \
  php8.4-bcmath php8.4-curl php8.4-dom php8.4-gd \
  php8.4-mbstring php8.4-mysql php8.4-xml php8.4-zip \
  php8.4-intl php8.4-redis
```

Verify extensions:

```bash
php -m | grep -E "bcmath|curl|dom|gd|mbstring|openssl|pdo_mysql|xml|zip|redis"
```

---

### 3. Install Composer (Global)

```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
php -r "unlink('composer-setup.php');"
```

Verify:

```bash
composer -V
```

---

### 4. Install Node.js via NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 25
nvm use 25
```

Verify:

```bash
node -v
npm -v
```

---

### 5. Install Bun (Optional)

```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
bun -v
```

---

### 6. Install & Configure MySQL

```bash
sudo apt install -y mysql-server
sudo systemctl enable --now mysql
```

Access MySQL:

```bash
sudo mysql
```

Inside MySQL:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '';
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED WITH caching_sha2_password BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
```

Optional packet size increase:

```ini
# sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
max_allowed_packet = 512M
```

Restart MySQL:

```bash
sudo systemctl restart mysql
```

---

### 7. Install Apache2

```bash
sudo apt install -y apache2
sudo a2enmod rewrite
sudo systemctl restart apache2
```

---

### 8. Install phpMyAdmin

```bash
cd /var/www
sudo wget https://files.phpmyadmin.net/phpMyAdmin/5.2.3/phpMyAdmin-5.2.3-all-languages.tar.gz
sudo tar xzf *.tar.gz
sudo mv phpMyAdmin-5.2.3-all-languages phpmyadmin
sudo rm *.tar.gz
sudo mkdir -p phpmyadmin/tmp
sudo chown -R www-data:www-data phpmyadmin
sudo chmod 777 phpmyadmin/tmp
```

Configure:

```bash
cd phpmyadmin
sudo cp config.sample.inc.php config.inc.php
```

Edit `config.inc.php` as needed.

---

### 9. Configure Apache Virtual Host

Edit:

```
sudo nano /etc/apache2/sites-available/000-default.conf
```

Configuration:

```apache
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html/public

    Alias /phpmyadmin /var/www/phpmyadmin

    <Directory /var/www/html/public>
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

Reload Apache:

```bash
sudo systemctl reload apache2
```

---

### 10. Install Git & GitHub CLI

```bash
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update
sudo apt install -y git gh
```

Configure Git:

```bash
git config --global user.name "ATik HaSan"
git config --global user.email "atikhasan2700@gmail.com"
```

Authenticate GitHub CLI:

```bash
sudo apt update
sudo apt install gh
gh auth login
```

---

### 11. Install Redis

```bash
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
sudo apt update
sudo apt install -y redis
```

Verify:

```bash
redis-cli ping
```

---

### 12. Final Version Check

```bash
php -v
composer -V
laravel -V
node -v
npm -v
bun -v
mysql --version
git -v
redis-cli --version
```
