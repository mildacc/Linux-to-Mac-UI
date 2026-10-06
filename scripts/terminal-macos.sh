#!/usr/bin/env bash
# Терминал в стиле macOS: zsh + oh-my-posh + MesloLGS NF, автодополнение и история.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

FONT_SIZE=13
DO_CHSH=false
WITH_PLUGINS=true
WITH_EXTRAS=false
OPACITY=""

FONT_DIR="$HOME/.local/share/fonts/MesloLGS"
THEME_DIR="$HOME/.config/oh-my-posh"
THEME_FILE="$THEME_DIR/macos.omp.json"
ZSHRC="$HOME/.zshrc"
ZSH_BEGIN="# >>> ubuntu-macos-theme >>>"
ZSH_END="# <<< ubuntu-macos-theme <<<"

usage() {
    cat <<'EOF'
Использование: terminal-macos.sh [опции]

  --chsh             сделать zsh оболочкой входа (chsh)
  --no-plugins       не ставить zsh-autosuggestions / zsh-syntax-highlighting
  --extras           eza, bat, fd, ripgrep, fzf + алиасы macOS (open, pbcopy, pbpaste)
  --font-size N      размер шрифта в терминале (по умолчанию 13)
  --opacity 0.0-1.0  прозрачность профиля Ptyxis по умолчанию (например 0.92)
  -h, --help         эта справка
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --chsh)       DO_CHSH=true ;;
            --no-plugins) WITH_PLUGINS=false ;;
            --extras)     WITH_EXTRAS=true ;;
            --font-size)  FONT_SIZE="${2:?--font-size требует значение}"; shift ;;
            --opacity)    OPACITY="${2:?--opacity требует значение}"; shift ;;
            -h|--help)    usage; exit 0 ;;
            *)            usage; die "Неизвестная опция: $1" ;;
        esac
        shift
    done
    [[ "$FONT_SIZE" =~ ^[0-9]+$ ]] || die "--font-size: ожидается целое число"
    [[ -z "$OPACITY" || "$OPACITY" =~ ^(0(\.[0-9]+)?|1(\.0+)?)$ ]] || die "--opacity: ожидается число 0.0–1.0"
}

install_deps() {
    step 1/5 "Зависимости..."
    command -v oh-my-posh &>/dev/null || die "oh-my-posh не найден. Установка: curl -s https://ohmyposh.dev/install.sh | bash -s"

    local pkgs=(zsh curl fontconfig)
    $WITH_PLUGINS && pkgs+=(zsh-autosuggestions zsh-syntax-highlighting)
    $WITH_EXTRAS && pkgs+=(eza bat fd-find ripgrep fzf wl-clipboard xdg-utils)
    local missing=() p
    for p in "${pkgs[@]}"; do
        dpkg -s "$p" &>/dev/null || missing+=("$p")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        sudo apt update
        sudo apt install -y "${missing[@]}"
    fi
    ok "oh-my-posh $(oh-my-posh version 2>/dev/null || echo '?'), zsh $(zsh --version | awk '{print $2}')"
}

install_font() {
    step 2/5 "Шрифт MesloLGS NF..."
    local base="https://github.com/romkatv/powerlevel10k-media/raw/master" f all_ok=true
    mkdir -p "$FONT_DIR"
    for f in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" \
             "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
        if [[ -f "$FONT_DIR/$f" ]]; then
            log "   ⏭️  $f"
        elif curl -fsSL "$base/${f// /%20}" -o "$FONT_DIR/$f"; then
            log "   ✅ $f"
        else
            rm -f "$FONT_DIR/$f"; warn "Не удалось скачать $f"; all_ok=false
        fi
    done
    fc-cache -f "$FONT_DIR" >/dev/null
    if $all_ok; then ok "MesloLGS NF установлен"; else warn "Шрифт установлен не полностью — иконки в промпте могут не отображаться"; fi
}

write_theme() {
    step 3/5 "Тема oh-my-posh..."
    mkdir -p "$THEME_DIR"
    backup_file "$THEME_FILE"
    cat > "$THEME_FILE" <<'EOF'
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 4,
  "final_space": true,
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "type": "text",
          "style": "plain",
          "foreground": "#6E9FE0",
          "template": " "
        },
        {
          "type": "path",
          "style": "plain",
          "foreground": "#C5C8C6",
          "options": {
            "style": "agnoster_short",
            "max_depth": 3
          },
          "template": "{{ .Path }}"
        },
        {
          "type": "git",
          "style": "plain",
          "foreground": "#A8CC8C",
          "foreground_templates": [
            "{{ if .Working.Changed }}#F0C27F{{ end }}",
            "{{ if .Staging.Changed }}#E06C75{{ end }}"
          ],
          "options": {
            "fetch_status": true
          },
          "template": "  {{ .HEAD }}{{ if .Working.Changed }} ±{{ end }}{{ if .Staging.Changed }} ●{{ end }}"
        },
        {
          "type": "node",
          "style": "plain",
          "foreground": "#6EBF87",
          "template": "  {{ .Full }}",
          "options": {
            "display_mode": "files"
          }
        },
        {
          "type": "python",
          "style": "plain",
          "foreground": "#6EBF87",
          "template": "  {{ .Full }}",
          "options": {
            "display_mode": "files"
          }
        }
      ]
    },
    {
      "type": "prompt",
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "type": "status",
          "style": "plain",
          "foreground": "#A8CC8C",
          "foreground_templates": [
            "{{ if .Error }}#E06C75{{ end }}"
          ],
          "options": {
            "always_enabled": true
          },
          "template": "❯ "
        }
      ]
    }
  ]
}
EOF
    if oh-my-posh print primary --config "$THEME_FILE" --shell zsh &>/dev/null; then
        ok "Тема: $THEME_FILE"
    else
        warn "oh-my-posh не смог отрисовать тему — обновите oh-my-posh: oh-my-posh upgrade"
    fi
}

configure_zshrc() {
    step 4/5 "Настройка ~/.zshrc..."
    touch "$ZSHRC"
    backup_file "$ZSHRC"

    # Наследие версий 1.x: строка eval и комментарий над ней
    sed -i --follow-symlinks -e '/^# oh-my-posh macOS theme$/d' -e '/oh-my-posh init zsh --config .*macos\.omp\.json/d' "$ZSHRC"
    remove_block "$ZSHRC" "$ZSH_BEGIN" "$ZSH_END"

    # Не дублируем то, что уже настроено вне блока (например, вручную по docs/tips.md)
    local have_hist=false have_as=false have_hl=false have_compinit=false
    grep -qE '^\s*HISTSIZE=' "$ZSHRC"               && have_hist=true
    grep -q 'zsh-autosuggestions.zsh' "$ZSHRC"      && have_as=true
    grep -q 'zsh-syntax-highlighting.zsh' "$ZSHRC"  && have_hl=true
    grep -qE 'compinit|oh-my-zsh\.sh' "$ZSHRC"      && have_compinit=true

    {
        if ! $have_compinit; then
            cat <<'EOF'
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
EOF
        fi
        if ! $have_hist; then
            cat <<'EOF'
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
EOF
        fi
        # shellcheck disable=SC2016  # $(...) должно попасть в .zshrc как есть
        printf 'eval "$(oh-my-posh init zsh --config %q)"\n' "$THEME_FILE"
        if $WITH_EXTRAS; then
            # Стандартные cat/find/grep не подменяются — только новые имена и ls
            cat <<'EOF'
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -la --icons=auto --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons=auto'
fi
(( $+commands[batcat] )) && alias bat='batcat'
(( $+commands[fdfind] )) && alias fd='fdfind'
alias open='xdg-open'
alias pbcopy='wl-copy'
alias pbpaste='wl-paste --no-newline'
[[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
EOF
        fi
        if $WITH_PLUGINS && ! $have_as; then
            echo '[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
        fi
        # syntax-highlighting должен подключаться последним
        if $WITH_PLUGINS && ! $have_hl; then
            echo '[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'
        fi
    } | replace_block "$ZSHRC" "$ZSH_BEGIN" "$ZSH_END"

    if zsh -n "$ZSHRC"; then ok ".zshrc обновлён (блок между маркерами ubuntu-macos-theme)"; else warn "zsh -n нашёл ошибку синтаксиса в .zshrc — проверьте файл"; fi

    if $DO_CHSH && [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
        chsh -s "$(command -v zsh)" && ok "zsh — оболочка входа (вступит в силу после перелогина)"
    fi
}

configure_terminal() {
    step 5/5 "Шрифт в терминале..."
    local font="MesloLGS NF $FONT_SIZE"
    if schema_exists org.gnome.Ptyxis; then
        # В Ptyxis шрифт общий для всех профилей
        gset org.gnome.Ptyxis use-system-font false
        gset org.gnome.Ptyxis font-name "$font"
        if [[ -n "$OPACITY" ]]; then
            local uuid
            uuid=$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")
            if [[ -n "$uuid" ]]; then
                gset "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$uuid/" opacity "$OPACITY"
            else
                warn "Профиль Ptyxis ещё не создан — запустите Ptyxis один раз и повторите с --opacity"
            fi
        fi
        ok "Ptyxis: $font"
    elif schema_exists org.gnome.Terminal.ProfilesList; then
        local profile
        profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
        local schema="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"
        gset "$schema" use-system-font false
        gset "$schema" font "$font"
        ok "GNOME Terminal: $font"
    else
        warn "Ptyxis/GNOME Terminal не найдены — выберите шрифт «$font» в настройках терминала вручную"
    fi
}

summary() {
    log ""
    log "✅ Терминал настроен. Лог: $LOGFILE"
    log "🔄 Применить сейчас: exec zsh"
    log "↩️  Откат: ./scripts/uninstall.sh --terminal"
}

main() {
    parse_args "$@"
    require_user
    log "=== 🖥️  Терминал в стиле macOS ==="
    start_log terminal-setup.log
    check_system
    install_deps
    install_font
    write_theme
    configure_zshrc
    configure_terminal
    summary
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
