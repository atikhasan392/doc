# WSL2 Development Environment

A **clean, reproducible, minimal‑friction development environment** for Laravel using **Windows 11 + WSL2 + Ubuntu 24.04**.

Goal of this guide:

- Minimal manual steps
- Mostly **single command blocks**
- Reproducible environment
- Close to production stack
- Optimized for Laravel development

Stack:

- Windows 11
- WSL2
- Ubuntu 24.04 LTS
- PHP 8.5
- Composer
- Node 24+ (via NVM)
- Bun
- MySQL 8.4
- Redis
- Git + GitHub CLI
- Laravel 12

---

# 1. Install WSL2 + Ubuntu

Open **PowerShell as Administrator**.

```powershell
wsl --install
wsl --install -d Ubuntu-24.04
```

Restart Windows if prompted.

Launch Ubuntu and create your user account.

---

# 2. Configure WSL Resources (Recommended)

Create this file in Windows:

```
C:\Users\YOUR_USERNAME\.wslconfig
```

```ini
[wsl2]
memory=16GB
processors=8
swap=8GB
```

Apply the configuration:

```powershell
wsl --shutdown
```

Restart Ubuntu.

---

# 3. System Update + Base Tools

Run once after Ubuntu installation.

```bash
sudo apt update && sudo apt upgrade -y && \
sudo apt install -y \
software-properties-common \
ca-certificates \
curl \
wget \
gnupg \
lsb-release \
unzip \
build-essential \
git
```

---

# 4. Install PHP 8.5 + Laravel Extensions

Add the trusted PHP repository maintained by **Ondřej Surý**.

```bash
sudo add-apt-repository ppa:ondrej/php -y && sudo apt update
```

Install PHP and common Laravel extensions in **one command**.

```bash
sudo apt install -y \
php8.5 \
php8.5-cli \
php8.5-fpm \
php8.5-bcmath \
php8.5-curl \
php8.5-dom \
php8.5-gd \
php8.5-imagick \
php8.5-intl \
php8.5-mbstring \
php8.5-mysql \
php8.5-pcntl \
php8.5-redis \
php8.5-xml \
php8.5-zip
```

Verify:

```bash
php -v
php -m | grep -E "bcmath|curl|dom|gd|mbstring|mysql|redis|xml|zip"
```

---

# 5. Install Composer

```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
php composer-setup.php && \
sudo mv composer.phar /usr/local/bin/composer && \
php -r "unlink('composer-setup.php');"
```

Verify:

```bash
composer -V
```

---

# 6. Install Node (via NVM)

Install NVM:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
```

Reload shell:

```bash
source ~/.bashrc
```

Install Node:

```bash
nvm install --lts
nvm use --lts
```

Verify:

```bash
node -v
npm -v
```

---

# 7. Install Bun

```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
```

Verify:

```bash
bun -v
```

---

# 8. Install MySQL

```bash
sudo apt install -y mysql-server && \
sudo systemctl enable --now mysql
```

Secure MySQL:

```bash
sudo mysql_secure_installation
```

Verify:

```bash
mysql --version
```

---

# 9. Install Redis

```bash
sudo apt install -y redis-server && \
sudo systemctl enable --now redis-server
```

Verify:

```bash
redis-cli ping
```

Expected output:

```
PONG
```

---

# 10. Install Git + GitHub CLI

Install Git and GitHub CLI.

```bash
sudo add-apt-repository ppa:git-core/ppa -y && \
sudo apt update && \
sudo apt install -y git gh
```

Configure Git:

```bash
git config --global user.name "YOUR NAME"

git config --global user.email "YOUR_EMAIL"
```

Authenticate GitHub CLI:

```bash
gh auth login
```

---

# 11. Install Laravel Installer

```bash
composer global require laravel/installer
```

Add Composer global binaries to PATH.

```bash
echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verify:

```bash
laravel --version
```

---

# 12. Create Laravel Project

Recommended project directory:

```bash
mkdir -p ~/projects
cd ~/projects
```

Create a Laravel application.

```bash
laravel new example-app
```

Run development server.

```bash
cd example-app
php artisan serve
```

---

# 13. Quick Environment Check

```bash
php -v
composer -V
node -v
npm -v
bun -v
mysql --version
redis-cli --version
git --version
```
