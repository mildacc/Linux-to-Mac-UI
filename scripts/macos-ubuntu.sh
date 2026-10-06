#!/usr/bin/env bash
# Оформление Ubuntu 26.04 (GNOME 50) в стиле macOS: WhiteSur, шрифты, обои, расширения, док.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# ---------- параметры ----------
COLOR="dark"            # dark | light
ACCENT="default"        # WhiteSur: default blue purple pink red orange yellow green grey
USE_SF=true             # false → Inter вместо San Francisco
USE_DASH_TO_DOCK=true   # false → настраивать встроенный Ubuntu Dock
DO_GDM=false
DO_FLATPAK=false
DO_FIREFOX=false

WORK_DIR=""
BACKUP_DIR="$HOME/backup_themes_$(timestamp)"
FONT_DIR="$HOME/.local/share/fonts"
WALLPAPER_DIR="$HOME/.local/share/backgrounds"
WALLPAPER_BASE="https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k"

DTD_UUID="dash-to-dock@micxgx.gmail.com"
UBUNTU_DOCK_UUID="ubuntu-dock@ubuntu.com"
BMS_UUID="blur-my-shell@aunetx"
USER_THEME_UUID="user-theme@gnome-shell-extensions.gcampax.github.com"
APPINDICATOR_UUID="ubuntu-appindicators@ubuntu.com"

usage() {
    cat <<'EOF'
Использование: macos-ubuntu.sh [опции]

  --light            светлый вариант (по умолчанию тёмный)
  --accent ЦВЕТ      акцент: default blue purple pink red orange yellow green grey
  --inter            шрифт Inter (свободная лицензия) вместо San Francisco
  --ubuntu-dock      не ставить Dash to Dock, настроить встроенный Ubuntu Dock
  --gdm              тема экрана входа WhiteSur (sudo; откат: см. docs/macos-ubuntu.md)
  --flatpak          тема WhiteSur для Flatpak-приложений
  --firefox          тема WhiteSur для Firefox
  -h, --help         эта справка
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --light)       COLOR="light" ;;
            --accent)      ACCENT="${2:?--accent требует значение}"; shift ;;
            --inter)       USE_SF=false ;;
            --ubuntu-dock) USE_DASH_TO_DOCK=false ;;
            --gdm)         DO_GDM=true ;;
            --flatpak)     DO_FLATPAK=true ;;
            --firefox)     DO_FIREFOX=true ;;
            -h|--help)     usage; exit 0 ;;
            *)             usage; die "Неизвестная опция: $1" ;;
        esac
        shift
    done
    case "$ACCENT" in
        default|blue|purple|pink|red|orange|yellow|green|grey) ;;
        *) die "Неизвестный акцент: $ACCENT" ;;
    esac
}

# WhiteSur accent → org.gnome.desktop.interface accent-color
gnome_accent() {
    case "$ACCENT" in
        default) echo blue ;;
        grey)    echo slate ;;
        *)       echo "$ACCENT" ;;
    esac
}

cleanup() { [[ -n "$WORK_DIR" ]] && rm -rf "$WORK_DIR"; return 0; }

# ---------- шаги ----------
install_deps() {
    step 1/9 "Установка зависимостей..."
    sudo apt update
    sudo apt install -y \
        git curl unzip python3 \
        sassc libglib2.0-dev-bin libglib2.0-bin \
        gnome-tweaks gnome-shell-extensions gnome-shell-extension-manager \
        gnome-shell-extension-user-theme \
        fonts-inter fonts-jetbrains-mono
    ok "Зависимости установлены"
}

backup_old() {
    step 2/9 "Backup предыдущей установки WhiteSur..."
    local found=false p
    mkdir -p "$BACKUP_DIR"
    for p in "$HOME"/.themes/WhiteSur* "$HOME"/.icons/WhiteSur* "$HOME"/.local/share/icons/WhiteSur*; do
        [[ -e "$p" ]] || continue
        found=true
        mkdir -p "$BACKUP_DIR$(dirname "${p#"$HOME"}")"
        mv "$p" "$BACKUP_DIR${p#"$HOME"}"
    done
    # WhiteSur -l удаляет ~/.config/gtk-4.0/gtk.css — сохраняем
    if [[ -e "$GTK4_DIR/gtk.css" ]]; then
        found=true
        mkdir -p "$BACKUP_DIR/.config/gtk-4.0"
        cp -aL "$GTK4_DIR/gtk.css" "$BACKUP_DIR/.config/gtk-4.0/"
    fi
    if $found; then
        log "📦 Backup: $BACKUP_DIR"
    else
        rmdir "$BACKUP_DIR" 2>/dev/null || true
        log "⏭️  Предыдущей установки нет"
    fi
    # Остальное содержимое ~/.themes и ~/.icons не трогаем
}

install_whitesur() {
    step 3/9 "Установка WhiteSur: тема, иконки, курсоры..."
    cd "$WORK_DIR"
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-cursors.git

    # -l: тема и для GTK4/libadwaita (Nautilus, Настройки, Ptyxis), иначе они остаются в Adwaita
    (cd WhiteSur-gtk-theme  && ./install.sh -c "$COLOR" -t "$ACCENT" -N mojave -l)
    (cd WhiteSur-icon-theme && ./install.sh -a)
    (cd WhiteSur-cursors    && ./install.sh)

    local tw=()
    $DO_FLATPAK && tw+=(-F -c "$COLOR" -t "$ACCENT")
    $DO_FIREFOX && tw+=(-f)
    if [[ ${#tw[@]} -gt 0 ]]; then
        (cd WhiteSur-gtk-theme && ./tweaks.sh "${tw[@]}") || warn "tweaks.sh ${tw[*]} завершился с ошибкой"
    fi
    # libadwaita-приложения во Flatpak читают ~/.config/gtk-4.0 только с этим разрешением
    if $DO_FLATPAK && command -v flatpak &>/dev/null; then
        flatpak override --user --filesystem=xdg-config/gtk-4.0:ro || warn "flatpak override не применён"
    fi
    if $DO_GDM; then
        warn "Тема GDM: WhiteSur рассчитан на GNOME ≤48. Откат: sudo ./tweaks.sh -g -r в каталоге WhiteSur-gtk-theme"
        (cd WhiteSur-gtk-theme && sudo ./tweaks.sh -g) || warn "Не удалось установить тему GDM"
    fi
    ok "WhiteSur установлен"
}

install_fonts() {
    step 4/9 "Шрифты..."
    if ! $USE_SF; then
        log "⏭️  San Francisco пропущен (--inter), используется Inter"
        return 0
    fi
    # Лицензия Apple не разрешает использование SF вне платформ Apple — на ваше усмотрение.
    git clone --depth=1 https://github.com/supermarin/YosemiteSanFranciscoFont.git "$WORK_DIR/sf"
    mkdir -p "$FONT_DIR/SanFrancisco"
    find "$WORK_DIR/sf" -name '*.ttf' -exec cp {} "$FONT_DIR/SanFrancisco/" \;
    fc-cache -f "$FONT_DIR" >/dev/null
    if fc-list -q "SFNS Display"; then
        ok "San Francisco установлен (семейства: SFNS Display, SFNS Text)"
    else
        warn "San Francisco не найден после установки — будет Inter"
    fi
}

install_wallpaper() {
    step 5/9 "Обои WhiteSur..."
    mkdir -p "$WALLPAPER_DIR"
    local v ok_all=true
    for v in light dark; do
        curl -fsSL "$WALLPAPER_BASE/WhiteSur-$v.jpg" -o "$WALLPAPER_DIR/WhiteSur-$v.jpg" || ok_all=false
    done
    if $ok_all; then
        gset org.gnome.desktop.background picture-uri      "file://$WALLPAPER_DIR/WhiteSur-light.jpg"
        gset org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_DIR/WhiteSur-dark.jpg"
        gset org.gnome.desktop.background picture-options  "zoom"
        ok "Обои установлены (светлая и тёмная версии)"
    else
        warn "Не удалось загрузить обои — оставляем текущие"
    fi
}

install_extensions() {
    step 6/9 "Расширения GNOME Shell..."
    ext_enable "$USER_THEME_UUID"
    ext_enable "$APPINDICATOR_UUID"

    if ego_install "$BMS_UUID"; then
        ext_enable "$BMS_UUID"; ok "Blur My Shell"
    else
        warn "Blur My Shell: установите вручную — https://extensions.gnome.org/extension/3193/blur-my-shell/"
    fi

    if $USE_DASH_TO_DOCK; then
        if ego_install "$DTD_UUID"; then
            ext_disable "$UBUNTU_DOCK_UUID"
            ext_enable "$DTD_UUID"; ok "Dash to Dock (Ubuntu Dock отключён)"
        else
            warn "Dash to Dock не установлен — остаётся Ubuntu Dock"
            USE_DASH_TO_DOCK=false
        fi
    fi
    log "ℹ️  Новые расширения активируются после выхода и входа в сессию (X11 в 26.04 нет, перезапуск оболочки недоступен)"
}

apply_appearance() {
    step 7/9 "Применение темы, цветов и шрифтов..."
    local Cap="${COLOR^}" ui doc title mono
    gset org.gnome.desktop.interface color-scheme  "prefer-$COLOR"
    gset org.gnome.desktop.interface accent-color  "$(gnome_accent)"
    gset org.gnome.desktop.interface gtk-theme     "WhiteSur-$Cap"
    gset org.gnome.desktop.wm.preferences theme    "WhiteSur-$Cap"
    gset org.gnome.desktop.interface icon-theme    "WhiteSur-$COLOR"
    gset org.gnome.desktop.interface cursor-theme  "WhiteSur-cursors"
    gset org.gnome.shell.extensions.user-theme name "WhiteSur-$Cap"

    # gsettings принимает любую строку — наличие шрифта проверяем через fontconfig
    if $USE_SF && fc-list -q "SFNS Display"; then
        ui="SFNS Display 11"; title="SFNS Display Bold 11"
        if fc-list -q "SFNS Text"; then doc="SFNS Text 11"; else doc="SFNS Display 11"; fi
    elif fc-list -q "Inter"; then
        ui="Inter 11"; doc="Inter 11"; title="Inter Bold 11"
    else
        ui="Ubuntu Sans 11"; doc="Ubuntu Sans 11"; title="Ubuntu Sans Bold 11"
    fi
    if fc-list -q "JetBrains Mono"; then mono="JetBrains Mono 11"; else mono="Ubuntu Sans Mono 12"; fi

    gset org.gnome.desktop.interface font-name           "$ui"
    gset org.gnome.desktop.interface document-font-name  "$doc"
    gset org.gnome.desktop.interface monospace-font-name "$mono"
    gset org.gnome.desktop.wm.preferences titlebar-font  "$title"

    # Кнопки окна слева, как в macOS
    gset org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
    ok "Интерфейс: $ui · моно: $mono · тема WhiteSur-$Cap · акцент $(gnome_accent)"
}

configure_dock() {
    step 8/9 "Настройка дока..."
    # Ubuntu Dock — форк Dash to Dock с той же схемой org.gnome.shell.extensions.dash-to-dock
    local uuid="$UBUNTU_DOCK_UUID" s="org.gnome.shell.extensions.dash-to-dock"
    $USE_DASH_TO_DOCK && uuid="$DTD_UUID"

    ext_gset "$uuid" "$s" dock-position      'BOTTOM'
    ext_gset "$uuid" "$s" extend-height      false
    ext_gset "$uuid" "$s" dock-fixed         true
    ext_gset "$uuid" "$s" intellihide        false
    ext_gset "$uuid" "$s" show-apps-at-top   false
    # Прозрачный фон — иконки прямо на рабочем столе
    ext_gset "$uuid" "$s" transparency-mode  'FIXED'
    ext_gset "$uuid" "$s" customize-alphas   true
    ext_gset "$uuid" "$s" min-alpha          0.0
    ext_gset "$uuid" "$s" max-alpha          0.0
    ext_gset "$uuid" "$s" background-opacity 0.0
    # Blur My Shell не размывает док
    ext_gset "$BMS_UUID" org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur false
    ok "Док настроен ($uuid)"
}

finalize_gtk4() {
    step 9/9 "Подключение пользовательских стилей GTK4..."
    gtk4_rewire
    ok "$GTK4_DIR/gtk.css собран (WhiteSur + macos-*.css)"
}

summary() {
    log ""
    log "✅ ==============================="
    log "✅  Кастомизация завершена"
    log "✅ ==============================="
    log "📝 Лог: $LOGFILE"
    [[ -d "$BACKUP_DIR" ]] && log "📦 Backup: $BACKUP_DIR"
    log ""
    log "🔄 Выйдите из сессии и войдите снова — без этого расширения и тема оболочки не применятся."
    log "↩️  Откат: ./scripts/uninstall.sh --theme"
}

main() {
    parse_args "$@"
    require_user
    log "=== 🧩 macOS-оформление Ubuntu ==="
    start_log macos-setup.log
    check_system

    WORK_DIR=$(mktemp -d -t macos-setup.XXXXXX)
    trap cleanup EXIT

    install_deps
    backup_old
    install_whitesur
    install_fonts
    install_wallpaper
    install_extensions
    apply_appearance
    configure_dock
    finalize_gtk4
    summary
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
