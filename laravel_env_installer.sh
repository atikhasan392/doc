#!/usr/bin/env bash

# Laravel Development Environment Installer
# install (curl -s https://raw.githubusercontent.com/atikhasan392/doc/laravel_env_installer.sh | bash)
#
# This script automates the installation of a PHP/Laravel development environment on Ubuntu
# 22.04, 24.04, and WSL2. It installs PHP (with extensions), Composer, Node.js, MySQL 8.4,
# phpMyAdmin, Redis, Nginx, and the Laravel installer. The script is idempotent: it detects
# existing installations and avoids reinstalling packages that are already present.

set -euo pipefail

# Check for root permissions
if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root. Use sudo to run it."
  exit 1
fi

# Global variables to store user selections
PHP_VERSION=""
NODE_VERSION=""
MYSQL_ROOT_PASSWORD=""

# Prompt the user to select the PHP version
select_php_version() {
  echo "Select PHP version to install:"
  select choice in "8.4" "8.5"; do
    case "$choice" in
      "8.4"|"8.5")
        PHP_VERSION="$choice"
        break
        ;;
      *)
        echo "Invalid selection. Please choose 8.4 or 8.5."
        ;;
    esac
  done
}

# Prompt the user to select the Node.js version
select_node_version() {
  echo "Select Node.js version to install:"
  select choice in "24.14.0 (LTS)" "25.8.1 (Current)"; do
    case "$choice" in
      "24.14.0 (LTS)")
        NODE_VERSION="24.14.0"
        break
        ;;
      "25.8.1 (Current)")
        NODE_VERSION="25.8.1"
        break
        ;;
      *)
        echo "Invalid selection."
        ;;
    esac
  done
}

# Prompt for MySQL root password
prompt_mysql_password() {
  read -rp "Enter MySQL root password (leave blank for no password): " MYSQL_ROOT_PASSWORD
}

# Install PHP and required extensions
install_php() {
  local version="$1"
  if php -v 2>/dev/null | grep -q "PHP $version"; then
    echo "PHP $version is already installed."
    return
  fi
  echo "Installing PHP $version and extensions..."
  apt-get update
  apt-get install -y software-properties-common ca-certificates lsb-release
  add-apt-repository -y ppa:ondrej/php
  apt-get update
  apt-get install -y \
    "php${version}" \
    "php${version}-fpm" \
    "php${version}-cli" \
    "php${version}-bcmath" \
    "php${version}-curl" \
    "php${version}-dom" \
    "php${version}-fileinfo" \
    "php${version}-gd" \
    "php${version}-intl" \
    "php${version}-mbstring" \
    "php${version}-mysql" \
    "php${version}-opcache" \
    "php${version}-pcntl" \
    "php${version}-redis" \
    "php${version}-tokenizer" \
    "php${version}-xml" \
    "php${version}-zip"
  systemctl enable --now "php${version}-fpm"
}

# Install Composer globally
install_composer() {
  if command -v composer >/dev/null 2>&1; then
    echo "Composer is already installed."
    return
  fi
  echo "Installing Composer..."
  apt-get install -y curl php-cli php-zip php-curl php-mbstring git unzip
  EXPECTED_SIGNATURE=$(curl -fsSL https://composer.github.io/installer.sig)
  curl -sS https://getcomposer.org/installer -o composer-setup.php
  ACTUAL_SIGNATURE=$(php -r "echo hash_file('sha384', 'composer-setup.php');")
  if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    echo "ERROR: Invalid Composer installer signature"
    rm composer-setup.php
    exit 1
  fi
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm composer-setup.php
  composer --version
}

# Install Node.js via nvm
install_nvm_node() {
  local version="$1"
  if command -v node >/dev/null 2>&1 && node -v | grep -q "$version"; then
    echo "Node.js $version is already installed."
    return
  fi
  echo "Installing Node.js $version via nvm..."
  # Install nvm if not present
  if ! command -v nvm >/dev/null 2>&1; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
  fi
  # Load nvm into current shell
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  # Install specified Node.js version
  nvm install "$version"
  nvm alias default "$version"
  node --version
  npm --version || true
}

# Install MySQL 8.4
install_mysql() {
  if mysql --version 2>/dev/null | grep -q "8.4"; then
    echo "MySQL 8.4 is already installed."
    return
  fi
  echo "Installing MySQL 8.4..."
  apt-get install -y wget lsb-release gnupg
  local config_deb="mysql-apt-config_0.8.35-1_all.deb"
  wget -q "https://dev.mysql.com/get/${config_deb}"
  # Preseed the selection for noninteractive installation
  DEBIAN_FRONTEND=noninteractive dpkg -i "${config_deb}" <<EOF
mysql-8.4-lts
EOF
  rm -f "${config_deb}"
  apt-get update
  # Preseed password if provided
  if [ -n "${MYSQL_ROOT_PASSWORD}" ]; then
    echo "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections
  fi
  DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
  systemctl enable --now mysql
}

# Install phpMyAdmin 5.2.3
install_phpmyadmin() {
  local php_version="$1"
  if [ -d "/var/www/phpmyadmin" ]; then
    echo "phpMyAdmin is already installed."
    return
  fi
  echo "Installing phpMyAdmin 5.2.3..."
  apt-get install -y curl tar unzip openssl
  local version="5.2.3"
  curl -fSL "https://files.phpmyadmin.net/phpMyAdmin/${version}/phpMyAdmin-${version}-all-languages.tar.gz" -o phpmyadmin.tar.gz
  tar -xf phpmyadmin.tar.gz
  mv phpMyAdmin-*-all-languages /var/www/phpmyadmin
  rm -f phpmyadmin.tar.gz
  install -d -m 0755 /var/www/phpmyadmin/tmp
  cp /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php
  local secret
  secret=$(openssl rand -hex 16)
  sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg['blowfish_secret'] = '${secret}';/" /var/www/phpmyadmin/config.inc.php
  # Configure MySQL root credentials
  if [ -n "${MYSQL_ROOT_PASSWORD}" ]; then
    cat >>/var/www/phpmyadmin/config.inc.php <<EOC
\$cfg['Servers'][1]['auth_type'] = 'config';
\$cfg['Servers'][1]['user'] = 'root';
\$cfg['Servers'][1]['password'] = '${MYSQL_ROOT_PASSWORD}';
EOC
  else
    echo "\$cfg['Servers'][1]['AllowNoPassword'] = true;" >>/var/www/phpmyadmin/config.inc.php
  fi
  chown -R www-data:www-data /var/www/phpmyadmin
  find /var/www/phpmyadmin/ -type d -exec chmod 755 {} \;
  find /var/www/phpmyadmin/ -type f -exec chmod 644 {} \;
  # Create Nginx snippet for phpMyAdmin
  cat >/etc/nginx/snippets/phpmyadmin.conf <<NGINX
location /phpmyadmin {
    alias /var/www/phpmyadmin/;
    index index.php index.html;
    location ~ ^/phpmyadmin/(.+\.php)\$ {
        alias /var/www/phpmyadmin/\$1;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
    }
    location ~* ^/phpmyadmin/(doc|sql|setup)/ {
        deny all;
    }
}
NGINX
  # Include the snippet in the default site if not already included
  if ! grep -q "phpmyadmin.conf" /etc/nginx/sites-available/default; then
    sed -i "/server_name _;/a \\tinclude snippets/phpmyadmin.conf;" /etc/nginx/sites-available/default
  fi
  nginx -t
  systemctl reload nginx
}

# Install Redis 8.6 from source
install_redis() {
  local version="8.6.0"
  if command -v redis-server >/dev/null 2>&1 && redis-server --version | grep -q "$version"; then
    echo "Redis ${version} is already installed."
    return
  fi
  echo "Installing Redis ${version} from source..."
  apt-get install -y build-essential ca-certificates wget gcc g++ libc6-dev libssl-dev make git cmake automake autoconf libtool
  pushd /usr/src >/dev/null
  wget -qO "redis-${version}.tar.gz" "https://github.com/redis/redis/archive/refs/tags/${version}.tar.gz"
  tar -xf "redis-${version}.tar.gz"
  rm -f "redis-${version}.tar.gz"
  cd "redis-${version}"
  export BUILD_TLS=yes BUILD_WITH_MODULES=yes DISABLE_WERRORS=yes
  make -j "$(nproc)" all
  make install
  popd >/dev/null
  # Create a redis user if not exists
  if ! id -u redis >/dev/null 2>&1; then
    adduser --system --group --no-create-home redis
  fi
  mkdir -p /etc/redis
  # Use default redis.conf from source
  cp /usr/src/redis-${version}/redis.conf /etc/redis/redis.conf
  sed -i "s/^supervised no/supervised systemd/" /etc/redis/redis.conf
  # Create systemd service
  cat >/etc/systemd/system/redis.service <<EOF
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  chown -R redis:redis /etc/redis
  systemctl daemon-reload
  systemctl enable --now redis.service
}

# Install Nginx and configure PHP-FPM
install_nginx() {
  if command -v nginx >/dev/null 2>&1; then
    echo "Nginx is already installed."
  else
    echo "Installing Nginx..."
    apt-get install -y nginx
    systemctl enable --now nginx
  fi
  # Ensure default server uses PHP-FPM
  local php_socket="/var/run/php/php${PHP_VERSION}-fpm.sock"
  if ! grep -q "fastcgi_pass unix:${php_socket}" /etc/nginx/sites-available/default; then
    # Remove existing PHP location blocks
    sed -i '/location ~ \\.php\\$ {/,/}/d' /etc/nginx/sites-available/default
    # Append PHP-FPM block
    cat >>/etc/nginx/sites-available/default <<NGINX

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_socket};
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
NGINX
    nginx -t
    systemctl reload nginx
  fi
}

# Install Laravel installer globally via Composer
install_laravel_installer() {
  if command -v laravel >/dev/null 2>&1; then
    echo "Laravel installer is already installed."
    return
  fi
  echo "Installing Laravel installer..."
  # Ensure composer is available
  if ! command -v composer >/dev/null 2>&1; then
    echo "Composer is required but not installed."
    return
  fi
  local composer_home="${HOME}/.config/composer"
  mkdir -p "${composer_home}"
  COMPOSER_HOME="${composer_home}" composer global require laravel/installer
  # Add composer vendor bin to PATH if missing
  if ! grep -q 'composer/vendor/bin' "${HOME}/.bashrc"; then
    echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >>"${HOME}/.bashrc"
  fi
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
  laravel --version || true
}

# Main installation routine
main() {
  select_php_version
  select_node_version
  prompt_mysql_password
  install_php "${PHP_VERSION}"
  install_composer
  install_nvm_node "${NODE_VERSION}"
  install_mysql
  install_nginx
  install_phpmyadmin "${PHP_VERSION}"
  install_redis
  install_laravel_installer
  echo ""
  echo "Installation summary:"
  echo "  PHP version:      ${PHP_VERSION}"
  echo "  Node.js version:  ${NODE_VERSION}"
  if [ -n "${MYSQL_ROOT_PASSWORD}" ]; then
    echo "  MySQL root password: set"
  else
    echo "  MySQL root password: not set"
  fi
  echo "  phpMyAdmin URL:   http://localhost/phpmyadmin/"
  echo ""
  echo "Restart your shell session or run 'source ~/.bashrc' to use the Laravel installer."
}

main "$@"
