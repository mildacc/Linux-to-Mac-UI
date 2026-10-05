#!/usr/bin/env bash
# Вход в GDM по PIN (как в macOS/Windows Hello): pam_pwdfile + bcrypt-хеш в /etc/pam-pin/passwd.
# Запуск: sudo ./scripts/pin-login.sh [--user ИМЯ] [--remove]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

PIN_DIR="/etc/pam-pin"
PIN_FILE="$PIN_DIR/passwd"
PAM_FILE="/etc/pam.d/gdm-password"
PAM_LINE="auth sufficient pam_pwdfile.so pwdfile=$PIN_FILE"

USERNAME="${SUDO_USER:-}"
DO_REMOVE=false

usage() {
    cat <<'EOF'
Использование: sudo pin-login.sh [опции]

  --user ИМЯ   пользователь (по умолчанию тот, кто вызвал sudo)
  --remove     удалить PIN пользователя; если PIN-ов не осталось — убрать строку из PAM
  -h, --help   эта справка

PIN принимают экран входа GDM и экран блокировки GNOME (служба PAM gdm-password).
sudo, polkit и связка ключей (gnome-keyring) по-прежнему требуют пароль.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)   USERNAME="${2:?--user требует значение}"; shift ;;
            --remove) DO_REMOVE=true ;;
            -h|--help) usage; exit 0 ;;
            *) usage; die "Неизвестная опция: $1" ;;
        esac
        shift
    done
}

require_root() {
    [[ $EUID -eq 0 ]] || die "Запустите через sudo: sudo $0 $*"
}

pam_backup() {
    local bak
    bak="$PAM_FILE.bak.$(timestamp)"
    cp -a "$PAM_FILE" "$bak"
    log "📦 Backup: $bak"
}

add_pin() {
    step 1/3 "Пакеты..."
    local missing=() p
    for p in libpam-pwdfile apache2-utils; do
        dpkg -s "$p" &>/dev/null || missing+=("$p")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        apt update -qq
        apt install -y "${missing[@]}"
    fi
    ok "libpam-pwdfile, apache2-utils"

    step 2/3 "PIN для $USERNAME..."
    local pin pin2
    read -rsp "PIN: " pin; echo
    read -rsp "Повторите PIN: " pin2; echo
    [[ "$pin" == "$pin2" ]] || die "PIN не совпадают"
    [[ ${#pin} -ge 4 ]] || die "PIN короче 4 символов"

    install -d -m 700 -o root -g root "$PIN_DIR"
    local create=()
    [[ -f "$PIN_FILE" ]] || create=(-c)
    # -i: PIN читается из stdin и не виден в списке процессов (в отличие от -b)
    printf '%s\n' "$pin" | htpasswd -i -B "${create[@]}" "$PIN_FILE" "$USERNAME"
    chown root:root "$PIN_FILE"
    chmod 600 "$PIN_FILE"
    ok "PIN сохранён (bcrypt) в $PIN_FILE"

    step 3/3 "PAM ($PAM_FILE)..."
    if grep -Fxq "$PAM_LINE" "$PAM_FILE"; then
        log "⏭️  Строка уже есть"
    else
        pam_backup
        # Первой строкой auth: PIN проверяется раньше пароля, при неудаче — обычный пароль
        if grep -q '^#%PAM' "$PAM_FILE"; then
            sed -i "/^#%PAM/a $PAM_LINE" "$PAM_FILE"
        else
            sed -i "1i $PAM_LINE" "$PAM_FILE"
        fi
        ok "Добавлено: $PAM_LINE"
    fi
}

remove_pin() {
    step 1/2 "Удаление PIN для $USERNAME..."
    if [[ -f "$PIN_FILE" ]]; then
        htpasswd -D "$PIN_FILE" "$USERNAME" || warn "$USERNAME не найден в $PIN_FILE"
    fi

    step 2/2 "PAM..."
    if [[ -s "$PIN_FILE" ]]; then
        log "⏭️  В $PIN_FILE остались другие пользователи — строку PAM не трогаю"
        return 0
    fi
    if grep -Fxq "$PAM_LINE" "$PAM_FILE"; then
        pam_backup
        sed -i "\\|^${PAM_LINE}\$|d" "$PAM_FILE"
        ok "Строка pam_pwdfile удалена из $PAM_FILE"
    fi
    rm -rf "$PIN_DIR"
    ok "Вход по PIN отключён"
}

main() {
    parse_args "$@"
    require_root "$@"
    [[ -n "$USERNAME" ]] || die "Не удалось определить пользователя — укажите --user ИМЯ"
    id "$USERNAME" &>/dev/null || die "Пользователь $USERNAME не существует"
    [[ -f "$PAM_FILE" ]] || die "$PAM_FILE не найден — GDM не установлен?"

    if $DO_REMOVE; then remove_pin; else add_pin; fi

    log ""
    log "🔄 Применится при следующем входе (или: sudo systemctl restart gdm — закроет сессию)"
    log "⚠️  После входа по PIN связка ключей не разблокируется автоматически — она запросит пароль"
    log "↩️  Откат: sudo $0 --remove   ·   вручную: восстановить $PAM_FILE.bak.*"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
