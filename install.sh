#!/usr/bin/env bash
# Установка компонентов ubuntu-macos-theme.
#   ./install.sh                      — всё: тема, терминал, Nautilus
#   ./install.sh theme nautilus       — только выбранные компоненты
#   ./install.sh pin                  — вход по PIN в GDM (не входит в «всё», спросит sudo)
#   ./install.sh theme -- --light     — опции после «--» передаются скрипту темы
# Опции каждого скрипта: ./scripts/<скрипт>.sh --help
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

components=()
theme_args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        theme|terminal|nautilus|pin) components+=("$1") ;;
        --) shift; theme_args=("$@"); break ;;
        -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "❌ Неизвестный компонент: $1 (theme | terminal | nautilus | pin)"; exit 1 ;;
    esac
    shift
done
[[ ${#components[@]} -gt 0 ]] || components=(theme terminal nautilus)

# Порядок важен: WhiteSur (-l) пересоздаёт ~/.config/gtk-4.0/gtk.css, поэтому тема идёт первой
failed=()
for c in theme terminal nautilus pin; do
    [[ " ${components[*]} " == *" $c "* ]] || continue
    case "$c" in
        theme)    "$ROOT/scripts/macos-ubuntu.sh" "${theme_args[@]}" || failed+=("$c") ;;
        terminal) "$ROOT/scripts/terminal-macos.sh" || failed+=("$c") ;;
        nautilus) "$ROOT/scripts/nautilus-macos.sh" || failed+=("$c") ;;
        pin)      sudo "$ROOT/scripts/pin-login.sh" || failed+=("$c") ;;
    esac
done

echo ""
if [[ ${#failed[@]} -gt 0 ]]; then
    echo "❌ С ошибкой: ${failed[*]} — подробности в ~/*-setup.log"
fi
echo "🔄 Выйдите из сессии и войдите снова, чтобы применились расширения и тема оболочки."
[[ ${#failed[@]} -eq 0 ]]
