#!/usr/bin/env bash
set -euo pipefail

# Настройка входа по PIN через GDM (GNOME).
# Использует libpam-pwdfile и htpasswd.
# После запуска можно входить по PIN вместо пароля.

if [ "$(id -u)" -ne 0 ]; then
  echo "Этот скрипт нужно запускать через sudo или от root"
  exit 1
fi

# --- Сбор данных ---
read -rp "Введите имя пользователя (логин): " USERNAME
read -s -rp "Введите PIN (будет вашим паролем при входе): " PIN
echo
read -s -rp "Повторите PIN: " PIN2
echo

if [ "$PIN" != "$PIN2" ]; then
  echo "PINы не совпадают! Прерываю."
  exit 1
fi

echo "Настройка PIN для пользователя: $USERNAME"

# --- Установка пакетов ---
apt update -qq
apt install -y libpam-pwdfile apache2-utils

# --- Создание файла с PIN ---
PIN_DIR="/etc/pam-pin"
PIN_FILE="$PIN_DIR/passwd"
mkdir -p "$PIN_DIR"
chmod 700 "$PIN_DIR"

if [ ! -f "$PIN_FILE" ]; then
  htpasswd -B -b -c "$PIN_FILE" "$USERNAME" "$PIN"
else
  htpasswd -B -b "$PIN_FILE" "$USERNAME" "$PIN"
fi

chmod 600 "$PIN_FILE"
chown root:root "$PIN_FILE"
echo "PIN сохранён в $PIN_FILE"

# --- Настройка PAM для GDM ---
FILE="/etc/pam.d/gdm-password"
BACKUP="$FILE.bak.$(date +%Y%m%d%H%M%S)"
cp -a "$FILE" "$BACKUP"
echo "Создана резервная копия: $BACKUP"

LINE="auth sufficient pam_pwdfile.so pwdfile=/etc/pam-pin/passwd"

if grep -Fq "$LINE" "$FILE"; then
  echo "Строка уже есть в $FILE — пропускаем."
else
  sed -i "1i$LINE" "$FILE"
  echo "Вставлена строка в $FILE:"
  echo "  $LINE"
fi

echo
echo "✅ Готово. Перезагрузите компьютер или перезапустите GDM:"
echo "   sudo systemctl restart gdm"
echo
echo "Если что-то пошло не так, восстановите резервную копию:"
echo "   sudo cp $BACKUP $FILE"
