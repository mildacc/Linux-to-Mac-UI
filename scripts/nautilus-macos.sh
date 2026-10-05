#!/usr/bin/env bash
# Nautilus 50 в стиле macOS Finder: поведение (gsettings) + стили (GTK4 CSS).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

WITH_CSS=true
WITH_ADMIN=false
CSS_FILE="$GTK4_DIR/macos-nautilus.css"
LEGACY_SCRIPT="$HOME/.local/share/nautilus/scripts/Открыть в терминале"

usage() {
    cat <<'EOF'
Использование: nautilus-macos.sh [опции]

  --no-css     только поведение, без собственных стилей (оставить чистый WhiteSur)
  --admin      установить nautilus-admin («Открыть как администратор»)
  -h, --help   эта справка
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-css) WITH_CSS=false ;;
            --admin)  WITH_ADMIN=true ;;
            -h|--help) usage; exit 0 ;;
            *) usage; die "Неизвестная опция: $1" ;;
        esac
        shift
    done
}

install_deps() {
    step 1/4 "Зависимости..."
    if $WITH_ADMIN; then
        sudo apt update
        if sudo apt install -y nautilus-admin; then
            ok "nautilus-admin установлен (проверьте пункт в контекстном меню — расширение давно не обновлялось)"
        else
            warn "nautilus-admin не установлен"
        fi
    else
        log "⏭️  Дополнительные пакеты не нужны (nautilus-admin — опция --admin)"
    fi
}

apply_settings() {
    step 2/4 "Настройки поведения..."
    local n=org.gnome.nautilus fc=org.gtk.gtk4.Settings.FileChooser

    # Вид списком, сортировка по имени
    gset $n.preferences default-folder-viewer 'list-view'
    gset $n.preferences default-sort-order 'name'
    gset $n.preferences default-sort-in-reverse-order false
    gset $n.preferences always-use-location-entry false
    gset $n.preferences open-folder-on-dnd-hover true
    gset $n.preferences recursive-search 'local-only'
    gset $n.preferences show-directory-item-counts 'local-only'

    # Папки первыми и скрытые файлы — общие с диалогом выбора файлов GTK4
    gset $fc sort-directories-first true
    gset $fc show-hidden false

    # Компактные строки списка, средние иконки сетки
    gset $n.list-view default-zoom-level 'small'
    gset $n.icon-view default-zoom-level 'medium'

    # Колонки как в Finder: имя, размер, тип, дата
    gset $n.list-view default-visible-columns "['name', 'size', 'type', 'date_modified']"
    gset $n.list-view default-column-order    "['name', 'size', 'type', 'date_modified']"

    ok "Настройки применены"
}

write_css() {
    step 3/4 "Стили Finder..."
    if ! $WITH_CSS; then
        rm -f "$CSS_FILE"
        gtk4_rewire
        log "⏭️  Собственные стили отключены (--no-css)"
        return 0
    fi
    mkdir -p "$GTK4_DIR"
    backup_file "$GTK4_DIR/gtk.css"

    # Селекторы сверены с исходниками Nautilus 50 (src/resources/style.css, nautilus-sidebar.c).
    # Все правила ограничены .nautilus-window, чтобы не задевать другие GTK4-приложения.
    cat > "$CSS_FILE" <<'EOF'
/* ubuntu-macos-theme: Nautilus в стиле Finder (Nautilus 50 / GTK4).
   Файл перезаписывается nautilus-macos.sh — свои правки держите в отдельном macos-*.css */

/* Боковая панель */
.nautilus-window placessidebar,
.nautilus-window placessidebar .navigation-sidebar {
    background-color: #1E2228;
    color: #C5C8C6;
}
.nautilus-window placessidebar {
    border-right: 1px solid #2A2D35;
}
.nautilus-window .navigation-sidebar > row {
    padding: 4px 8px;
    margin: 1px 6px;
    border-radius: 6px;
    font-size: 13px;
}
.nautilus-window .navigation-sidebar > row:selected {
    background-color: #3A6BC7;
    color: #FFFFFF;
}
.nautilus-window .navigation-sidebar > row:hover:not(:selected) {
    background-color: rgba(255, 255, 255, 0.07);
}

/* Область файлов */
.nautilus-window .nautilus-list-view columnview,
.nautilus-window .nautilus-grid-view gridview {
    background-color: #252830;
    color: #C5C8C6;
}
.nautilus-window .nautilus-list-view columnview > listview > row {
    border-radius: 4px;
}
.nautilus-window .nautilus-list-view columnview > listview > row:selected,
.nautilus-window .nautilus-grid-view gridview > child:selected {
    background-color: #3A6BC7;
    color: #FFFFFF;
}

/* Заголовки колонок */
.nautilus-window .nautilus-list-view columnview > header > button {
    background: transparent;
    border-bottom: 1px solid #2A2D35;
    color: #6B7280;
    font-size: 12px;
}

/* Панель заголовка */
.nautilus-window headerbar {
    background-color: #1A1D23;
    border-bottom: 1px solid #2A2D35;
}
.nautilus-window headerbar button:hover {
    background-color: rgba(255, 255, 255, 0.1);
}

/* Строка пути */
.nautilus-window .nautilus-path-button {
    color: #6E9FE0;
    font-size: 12px;
}
.nautilus-window .nautilus-path-button.current-dir {
    color: #C5C8C6;
}

/* Строка состояния (плавающая панель внизу) */
.nautilus-window .floating-bar {
    background-color: #1A1D23;
    color: #C5C8C6;
}

/* Тонкий скроллбар — только в Nautilus */
.nautilus-window scrollbar slider {
    min-width: 6px;
    min-height: 20px;
    border-radius: 3px;
    background-color: rgba(255, 255, 255, 0.2);
}
.nautilus-window scrollbar slider:hover {
    background-color: rgba(255, 255, 255, 0.35);
}
EOF
    gtk4_rewire
    ok "Стили: $CSS_FILE (подключены в gtk.css)"
}

cleanup_legacy() {
    step 4/4 "Очистка и перезапуск..."
    # Nautilus 50 умеет «Открыть в терминале» сам: правый клик по фону или Ctrl+.
    if [[ -f "$LEGACY_SCRIPT" ]]; then
        rm -f "$LEGACY_SCRIPT"
        log "🗑️  Удалён скрипт «Открыть в терминале» из версии 1.x — используйте встроенный пункт (Ctrl+.)"
    fi
    nautilus -q 2>/dev/null || true
    ok "Nautilus перезапущен"
}

summary() {
    log ""
    log "✅ Nautilus настроен. Лог: $LOGFILE"
    log "💡 Ctrl+. — открыть терминал в текущей папке · Ctrl+H — скрытые файлы · Ctrl+L — ввод пути"
    log "🔍 Проверить стили: GTK_DEBUG=interactive nautilus"
    log "↩️  Откат: ./scripts/uninstall.sh --nautilus"
}

main() {
    parse_args "$@"
    require_user
    log "=== 🗂️  Nautilus в стиле Finder ==="
    start_log nautilus-setup.log
    check_system
    install_deps
    apply_settings
    write_css
    cleanup_legacy
    summary
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
