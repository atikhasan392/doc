#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

LOG_FILE="$HOME/ubuntu-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

PMA_VERSION="5.2.3"
NODE_VERSION="22"

if [[ $EUID -eq 0 ]]; then
  echo "Do not run as root. Run as your user with sudo access."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo not found. Install sudo first."
  exit 1
fi

sudo -v

print_step() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

apt_update_upgrade() {
  sudo apt update -y
  sudo apt -y upgrade
}

apt_install() {
  sudo apt -y install --no-install-recommends "$@"
}

enable_fancy_apt_progress() {
  sudo mkdir -p /etc/apt/apt.conf.d
  echo 'Dpkg::Progress-Fancy "1";' | sudo tee /etc/apt/apt.conf.d/99progressbar >/dev/null
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

print_step "0) Base: update + utilities + fancy progress"
enable_fancy_apt_progress
apt_update_upgrade
apt_install software-properties-common ca-certificates curl gnupg lsb-release unzip wget tar xz-utils git build-essential

print_step "1) PHP 8.4 (Ondrej PPA) + extensions"
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update -y
apt_install \
  php8.4 php8.4-cli php8.4-common \
  php8.4-bcmath php8.4-curl php8.4-dom php8.4-gd \
  php8.4-mbstring php8.4-mysql php8.4-pdo-mysql \
  php8.4-pdo-sqlite php8.4-xml php8.4-zip \
  php8.4-mysqli php8.4-redis php8.4-intl

print_step "2) Composer (system-wide)"
if ! command_exists composer; then
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php composer-setup.php --quiet
  sudo mv composer.phar /usr/local/bin/composer
  rm -f composer-setup.php
fi

print_step "3) Node.js via NVM + Node ${NODE_VERSION}"
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"

nvm install "${NODE_VERSION}"
nvm use "${NODE_VERSION}"
nvm alias default "${NODE_VERSION}"

print_step "4) Bun"
if ! command_exists bun; then
  curl -fsSL https://bun.sh/install | bash
fi
# shellcheck disable=SC1091
[[ -s "$HOME/.bashrc" ]] && . "$HOME/.bashrc" || true
# shellcheck disable=SC1091
[[ -s "$HOME/.zshrc" ]] && . "$HOME/.zshrc" || true

print_step "5) MySQL 8 (safe local setup: dev user, keep root default)"
apt_install mysql-server
sudo systemctl enable --now mysql

MYSQL_DEV_USER="laravel"
MYSQL_DEV_PASS="laravel"

sudo mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_DEV_USER}'@'localhost' IDENTIFIED BY '${MYSQL_DEV_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_DEV_USER}'@'localhost' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"

print_step "6) Apache2 + PHP module + rewrite"
apt_install apache2 libapache2-mod-php8.4
sudo a2enmod rewrite
sudo systemctl enable --now apache2
sudo systemctl restart apache2

print_step "7) phpMyAdmin (manual install to /var/www/phpmyadmin) + Apache alias"
sudo mkdir -p /var/www
cd /tmp
wget -q "https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz"
sudo rm -rf /var/www/phpmyadmin
sudo tar xzf "phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz" -C /var/www
sudo mv "/var/www/phpMyAdmin-${PMA_VERSION}-all-languages" /var/www/phpmyadmin
rm -f "phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz"

sudo mkdir -p /var/www/phpmyadmin/tmp
sudo chown -R www-data:www-data /var/www/phpmyadmin
sudo chmod 770 /var/www/phpmyadmin/tmp

sudo cp /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php

BLOWFISH_SECRET="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)"
sudo sed -i "s/\\\$cfg\\['blowfish_secret'\\] = '';/\\\$cfg\\['blowfish_secret'\\] = '${BLOWFISH_SECRET}';/" /var/www/phpmyadmin/config.inc.php

sudo bash -lc "cat >/etc/apache2/conf-available/phpmyadmin.conf <<'EOF'
Alias /phpmyadmin /var/www/phpmyadmin

<Directory /var/www/phpmyadmin>
    Options FollowSymLinks
    DirectoryIndex index.php
    AllowOverride All
    Require all granted
</Directory>
EOF"

sudo a2enconf phpmyadmin
sudo systemctl reload apache2

print_step "8) Git (latest via PPA) + GitHub CLI"
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update -y
apt_install git gh

print_step "9) Redis"
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list >/dev/null
sudo apt update -y
apt_install redis
sudo systemctl enable --now redis-server

print_step "10) Cleanup"
sudo apt -y autoremove
sudo apt -y autoclean

print_step "11) Versions (table)"
php_ver="$(php -v 2>/dev/null | head -n 1 || true)"
composer_ver="$(composer -V 2>/dev/null || true)"
node_ver="$(node -v 2>/dev/null || true)"
npm_ver="$(npm -v 2>/dev/null || true)"
bun_ver="$(bun -v 2>/dev/null || true)"
mysql_ver="$(mysql --version 2>/dev/null || true)"
apache_ver="$(apache2 -v 2>/dev/null | head -n 1 || true)"
git_ver="$(git --version 2>/dev/null || true)"
gh_ver="$(gh --version 2>/dev/null | head -n 1 || true)"
redis_ver="$(redis-cli --version 2>/dev/null || true)"
pma_ver="phpMyAdmin ${PMA_VERSION}"

printf "\n%-18s | %s\n" "Component" "Version"
printf "%-18s-+-%s\n" "------------------" "----------------------------------------------"
printf "%-18s | %s\n" "PHP" "$php_ver"
printf "%-18s | %s\n" "Composer" "$composer_ver"
printf "%-18s | %s\n" "Node" "$node_ver"
printf "%-18s | %s\n" "npm" "$npm_ver"
printf "%-18s | %s\n" "Bun" "$bun_ver"
printf "%-18s | %s\n" "MySQL" "$mysql_ver"
printf "%-18s | %s\n" "Apache" "$apache_ver"
printf "%-18s | %s\n" "phpMyAdmin" "$pma_ver"
printf "%-18s | %s\n" "Git" "$git_ver"
printf "%-18s | %s\n" "GitHub CLI" "$gh_ver"
printf "%-18s | %s\n" "Redis" "$redis_ver"

echo
echo "phpMyAdmin: http://localhost/phpmyadmin"
echo "MySQL dev user: ${MYSQL_DEV_USER} / ${MYSQL_DEV_PASS}"
echo "Log saved to: ${LOG_FILE}"
