#!/usr/bin/env bash
# Откат изменений ubuntu-macos-theme. Трогает только то, что ставили скрипты проекта.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DO_THEME=false
DO_TERMINAL=false
DO_NAUTILUS=false
DO_PIN=false
ASSUME_YES=false

DTD_UUID="dash-to-dock@micxgx.gmail.com"
UBUNTU_DOCK_UUID="ubuntu-dock@ubuntu.com"
BMS_UUID="blur-my-shell@aunetx"
USER_THEME_UUID="user-theme@gnome-shell-extensions.gcampax.github.com"

usage() {
    cat <<'EOF'
Использование: uninstall.sh [--all] [--theme] [--terminal] [--nautilus] [--pin] [-y]

  --theme      WhiteSur, шрифты SF, обои, расширения, док, настройки интерфейса
  --terminal   блок в ~/.zshrc, тема oh-my-posh, шрифт терминала
  --nautilus   настройки Nautilus и macos-nautilus.css
  --pin        вход по PIN в GDM (запросит sudo)
  --all        всё перечисленное, кроме --pin
  -y           без подтверждения
EOF
}

parse_args() {
    [[ $# -gt 0 ]] || { usage; exit 1; }
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)      DO_THEME=true; DO_TERMINAL=true; DO_NAUTILUS=true ;;
            --theme)    DO_THEME=true ;;
            --terminal) DO_TERMINAL=true ;;
            --nautilus) DO_NAUTILUS=true ;;
            --pin)      DO_PIN=true ;;
            -y|--yes)   ASSUME_YES=true ;;
            -h|--help)  usage; exit 0 ;;
            *)          usage; die "Неизвестная опция: $1" ;;
        esac
        shift
    done
}

confirm() {
    $ASSUME_YES && return 0
    local what=()
    $DO_THEME && what+=(тема)
    $DO_TERMINAL && what+=(терминал)
    $DO_NAUTILUS && what+=(Nautilus)
    $DO_PIN && what+=(PIN-вход)
    read -rp "Откатить: ${what[*]}? [y/N] " ans
    [[ "$ans" =~ ^[YyДд]$ ]] || die "Отменено"
}

greset() {
    if gsettings writable "$1" "$2" &>/dev/null; then gsettings reset "$1" "$2"; fi
    return 0
}

uninstall_theme() {
    step theme "Откат оформления..."
    local k
    for k in gtk-theme icon-theme cursor-theme font-name document-font-name monospace-font-name color-scheme accent-color; do
        greset org.gnome.desktop.interface "$k"
    done
    for k in theme titlebar-font button-layout; do
        greset org.gnome.desktop.wm.preferences "$k"
    done
    for k in picture-uri picture-uri-dark picture-options; do
        greset org.gnome.desktop.background "$k"
    done
    greset org.gnome.shell.extensions.user-theme name

    # Расширения: вернуть Ubuntu Dock, убрать установленные скриптом
    ext_forget "$DTD_UUID"
    ext_forget "$BMS_UUID"
    ext_forget "$USER_THEME_UUID"
    _ext_list_edit disabled-extensions del "$UBUNTU_DOCK_UUID"
    gnome-extensions uninstall "$DTD_UUID" &>/dev/null || true
    gnome-extensions uninstall "$BMS_UUID" &>/dev/null || true
    if command -v dconf &>/dev/null; then
        dconf reset -f /org/gnome/shell/extensions/dash-to-dock/
        dconf reset -f /org/gnome/shell/extensions/blur-my-shell/
    else
        gsettings reset-recursively org.gnome.shell.extensions.dash-to-dock 2>/dev/null || true
    fi

    # Файлы WhiteSur
    rm -rf "$HOME"/.themes/WhiteSur* "$HOME"/.local/share/icons/WhiteSur* "$HOME"/.icons/WhiteSur*
    if [[ -e "$GTK4_DIR/gtk-Dark.css" || -e "$GTK4_DIR/gtk-Light.css" ]]; then
        rm -rf "$GTK4_DIR"/{gtk-Dark.css,gtk-Light.css,gtk-dark.css,assets,windows-assets}
    fi
    gtk4_rewire

    rm -rf "$HOME/.local/share/fonts/SanFrancisco"
    rm -f "$HOME"/.local/share/backgrounds/WhiteSur-{light,dark}.jpg
    fc-cache -f >/dev/null 2>&1 || true

    ok "Оформление откачено"
    log "ℹ️  Тема GDM (если ставили --gdm): sudo ./tweaks.sh -g -r в каталоге WhiteSur-gtk-theme"
    log "ℹ️  Flatpak (если ставили --flatpak): flatpak override --user --nofilesystem=xdg-config/gtk-4.0"
    log "ℹ️  Резервные копии прежних тем: ~/backup_themes_*"
}

uninstall_terminal() {
    step terminal "Откат терминала..."
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]]; then
        backup_file "$zshrc"
        remove_block "$zshrc" "# >>> ubuntu-macos-theme >>>" "# <<< ubuntu-macos-theme <<<"
        sed -i --follow-symlinks -e '/^# oh-my-posh macOS theme$/d' -e '/oh-my-posh init zsh --config .*macos\.omp\.json/d' "$zshrc"
    fi
    rm -f "$HOME/.config/oh-my-posh/macos.omp.json"
    greset org.gnome.Ptyxis font-name
    greset org.gnome.Ptyxis use-system-font
    local uuid
    uuid=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)
    [[ -n "$uuid" ]] && greset "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$uuid/" opacity
    ok "Терминал откачен (шрифт MesloLGS NF и пакеты zsh оставлены)"
}

uninstall_nautilus() {
    step nautilus "Откат Nautilus..."
    local n=org.gnome.nautilus fc=org.gtk.gtk4.Settings.FileChooser k
    for k in default-folder-viewer default-sort-order default-sort-in-reverse-order always-use-location-entry \
             open-folder-on-dnd-hover recursive-search show-directory-item-counts; do
        greset $n.preferences "$k"
    done
    for k in default-zoom-level default-visible-columns default-column-order; do
        greset $n.list-view "$k"
    done
    greset $n.icon-view default-zoom-level
    greset $fc sort-directories-first
    greset $fc show-hidden

    rm -f "$GTK4_DIR/macos-nautilus.css"
    gtk4_rewire
    nautilus -q 2>/dev/null || true
    ok "Nautilus откачен"
}

main() {
    parse_args "$@"
    require_user
    confirm
    $DO_THEME    && uninstall_theme
    $DO_TERMINAL && uninstall_terminal
    $DO_NAUTILUS && uninstall_nautilus
    if $DO_PIN; then sudo "$SCRIPT_DIR/pin-login.sh" --user "$USER" --remove; fi
    log ""
    log "🔄 Выйдите из сессии и войдите снова, чтобы изменения вступили в силу."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
