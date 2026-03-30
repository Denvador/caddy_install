#!/bin/bash

# Проверка на права root
if [ "$EUID" -ne 0 ]; then 
  echo "Пожалуйста, запустите скрипт от имени root (через sudo)"
  exit
fi

# Запрос домена у пользователя
echo "Введите ваш домен (например, example.com):"
read DOMAIN

if [ -z "$DOMAIN" ]; then
  echo "Ошибка: Домен не может быть пустым."
  exit 1
fi

echo "--- Начинаю установку Caddy ---"

# 1. Установка зависимостей и ключей репозитория
apt update && apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1G 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1G 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list

# 2. Установка Caddy
apt update
apt install -y caddy

# 3. Создание базовой директории для сайта (если ее нет)
mkdir -p /var/www/html
chown caddy:caddy /var/www/html

# 4. Настройка Caddyfile
echo "--- Настройка Caddyfile для $DOMAIN ---"
cat <<EOF > /etc/caddy/Caddyfile
$DOMAIN {
    # Путь к файлам сайта
    root * /var/www/html
    
    # Включаем сервер статических файлов
    file_server
    
    # Сжатие ответов
    encode zstd gzip

    # Логирование
    log {
        output file /var/log/caddy/access.log
    }
}
EOF

# 5. Перезапуск Caddy для применения настроек
systemctl reload caddy

echo "--- Установка завершена! ---"
echo "Домен: https://$DOMAIN"
echo "Корневая папка сайта: /var/www/html"
echo "Файл конфигурации: /etc/caddy/Caddyfile"
