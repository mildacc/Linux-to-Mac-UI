#!/usr/bin/env bash
# shellcheck shell=bash
# Общие функции для scripts/*.sh. Подключается через `source`, сам не запускается.

TARGET_UBUNTU="26.04"
TARGET_GNOME="50"

# ---------- вывод ----------
log()  { printf '%s\n' "$*"; }
ok()   { printf '✅ %s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*"; }
die()  { printf '❌ %s\n' "$*"; exit 1; }
step() { printf '\n[%s] %s\n' "$1" "$2"; }

require_user() {
    [[ $EUID -ne 0 ]] || die "Не запускайте от root — gsettings работает только в сессии пользователя. sudo скрипт запросит сам."
}

# start_log ИМЯ_ФАЙЛА — дублирует stdout/stderr в ~/ИМЯ_ФАЙЛА
start_log() {
    LOGFILE="$HOME/$1"
    exec > >(tee -a "$LOGFILE") 2>&1
    log "📝 Лог: $LOGFILE"
    log "🕐 Начало: $(date)"
}

# Проверка версии системы. Не прерывает выполнение — только предупреждает.
# Заполняет GNOME_MAJOR (например, 50).
check_system() {
    local ver=""
    if [[ -r /etc/os-release ]]; then
        ver=$(. /etc/os-release && echo "${VERSION_ID:-}")
    fi
    GNOME_MAJOR=$(gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)

    log "🖥️  Ubuntu ${ver:-?}, GNOME Shell ${GNOME_MAJOR:-?}, сессия ${XDG_SESSION_TYPE:-?}"
    [[ "$ver" == "$TARGET_UBUNTU" ]] || \
        warn "Скрипты проверены на Ubuntu $TARGET_UBUNTU. На ${ver:-неизвестной версии} возможны отличия."
    [[ -z "$GNOME_MAJOR" || "$GNOME_MAJOR" == "$TARGET_GNOME" ]] || \
        warn "Ожидается GNOME $TARGET_GNOME, найден $GNOME_MAJOR — часть ключей gsettings может отличаться."
}

# ---------- gsettings ----------
# schema_exists SCHEMA — без пайпа в grep -q (с pipefail он ловит SIGPIPE и даёт ложный отказ)
schema_exists() { gsettings list-keys "$1" &>/dev/null; }

# gset [--schemadir DIR] SCHEMA KEY VALUE
# Пишет ключ, только если он существует. Отсутствующий ключ — предупреждение, а не падение скрипта.
gset() {
    local sd=()
    if [[ "$1" == "--schemadir" ]]; then
        sd=(--schemadir "$2"); shift 2
    fi
    if gsettings "${sd[@]}" writable "$1" "$2" &>/dev/null; then
        gsettings "${sd[@]}" set "$1" "$2" "$3" || warn "Не удалось записать $1 $2 = $3"
    else
        warn "Ключ $1 $2 не найден — пропущено"
    fi
    return 0
}

# ---------- расширения GNOME Shell ----------
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"

# Каталог локальной схемы расширения (компилирует при необходимости). Пусто, если схемы нет.
ext_schemadir() {
    local d="$EXT_DIR/$1/schemas"
    [[ -d "$d" ]] || return 0
    if [[ ! -f "$d/gschemas.compiled" ]] && compgen -G "$d/*.gschema.xml" >/dev/null; then
        glib-compile-schemas "$d" 2>/dev/null || true
    fi
    [[ -f "$d/gschemas.compiled" ]] && echo "$d"
    return 0
}

# ext_gset UUID SCHEMA KEY VALUE — gset с локальной схемой расширения, если она есть
ext_gset() {
    local uuid="$1"; shift
    local d
    d=$(ext_schemadir "$uuid")
    if [[ -n "$d" ]]; then gset --schemadir "$d" "$@"; else gset "$@"; fi
}

# Правка списков org.gnome.shell enabled-extensions / disabled-extensions
_ext_list_edit() {
    local key="$1" op="$2" uuid="$3" cur new
    cur=$(gsettings get org.gnome.shell "$key" 2>/dev/null) || return 0
    new=$(python3 - "$cur" "$op" "$uuid" <<'PY'
import ast, sys
cur, op, uuid = sys.argv[1:]
cur = cur.strip()
if cur.startswith('@as'):
    cur = cur[3:].strip()
items = list(ast.literal_eval(cur)) if cur else []
if op == 'add' and uuid not in items:
    items.append(uuid)
elif op == 'del':
    items = [x for x in items if x != uuid]
print('[' + ', '.join(repr(x) for x in items) + ']')
PY
) || return 0
    gsettings set org.gnome.shell "$key" "$new" || warn "Не удалось изменить org.gnome.shell $key"
}

# Включение через gsettings работает и для только что установленного расширения:
# под Wayland оболочка подхватит его при следующем входе в сессию.
ext_enable() {
    gset org.gnome.shell disable-user-extensions false
    _ext_list_edit enabled-extensions add "$1"
    _ext_list_edit disabled-extensions del "$1"
}

ext_disable() {
    _ext_list_edit enabled-extensions del "$1"
    _ext_list_edit disabled-extensions add "$1"
}

# Убрать UUID из обоих списков (для удалённых расширений)
ext_forget() {
    _ext_list_edit enabled-extensions del "$1"
    _ext_list_edit disabled-extensions del "$1"
}

# ego_install UUID — установка с extensions.gnome.org под текущую версию GNOME Shell
ego_install() {
    local uuid="$1" info url tmp rc
    [[ -n "${GNOME_MAJOR:-}" ]] || { warn "Версия GNOME Shell не определена — $uuid пропущено"; return 1; }

    info=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${GNOME_MAJOR}") || {
        warn "$uuid: нет версии для GNOME $GNOME_MAJOR на extensions.gnome.org"; return 1; }
    url=$(python3 -c 'import sys, json; print(json.load(sys.stdin).get("download_url", ""))' <<<"$info" 2>/dev/null || true)
    [[ -n "$url" ]] || { warn "$uuid: не удалось получить ссылку на загрузку"; return 1; }

    tmp=$(mktemp --suffix=.zip)
    rc=0
    curl -fsSL "https://extensions.gnome.org${url}" -o "$tmp" && gnome-extensions install --force "$tmp" || rc=$?
    rm -f "$tmp"
    return "$rc"
}

# ---------- файлы ----------
timestamp() { date +%Y%m%d_%H%M%S; }

# backup_file ФАЙЛ — копия рядом с суффиксом .bak.ДАТА (если файл есть)
backup_file() {
    if [[ -e "$1" ]]; then
        cp -pL "$1" "$1.bak.$(timestamp)"   # -L: для симлинка копируем содержимое
        log "   📦 Backup: $1.bak.*"
    fi
    return 0
}

# remove_block ФАЙЛ НАЧАЛО КОНЕЦ — удаляет строки между маркерами (включительно)
remove_block() {
    local file="$1" begin="$2" end="$3" tmp
    [[ -f "$file" ]] || return 0
    tmp=$(mktemp)
    awk -v b="$begin" -v e="$end" '$0==b{s=1;next} $0==e{s=0;next} !s' "$file" > "$tmp"
    cat "$tmp" > "$file"
    rm -f "$tmp"
}

# replace_block ФАЙЛ НАЧАЛО КОНЕЦ < содержимое — заменяет блок между маркерами (или дописывает в конец).
# Повторный запуск не дублирует блок.
replace_block() {
    local file="$1" begin="$2" end="$3" body
    body=$(cat)
    touch "$file"
    remove_block "$file" "$begin" "$end"
    printf '%s\n%s\n%s\n' "$begin" "$body" "$end" >> "$file"
}

# ---------- GTK4 / libadwaita CSS ----------
# ~/.config/gtk-4.0/gtk.css собирается из блока @import:
#   * базовый CSS WhiteSur (gtk-Dark.css / gtk-Light.css), если установлен с -l;
#   * собственные стили проекта — ~/.config/gtk-4.0/macos-*.css.
# WhiteSur с флагом -l удаляет gtk.css и ставит симлинк — поэтому стили
# проекта хранятся в отдельных файлах, а gtk.css только их подключает.
GTK4_DIR="$HOME/.config/gtk-4.0"
GTK4_BEGIN='/* >>> ubuntu-macos-theme >>> */'
GTK4_END='/* <<< ubuntu-macos-theme <<< */'
LEGACY_NAUTILUS_BEGIN='/* ===== Nautilus macOS Finder style ===== */'
LEGACY_NAUTILUS_END='/* ===== конец Nautilus стиля ===== */'

gtk4_rewire() {
    local css="$GTK4_DIR/gtk.css" base="" target tmp imports="" f
    mkdir -p "$GTK4_DIR"

    if [[ -L "$css" ]]; then
        target=$(readlink -f "$css" || true)
        if [[ -n "$target" && "$(dirname "$target")" == "$(readlink -f "$GTK4_DIR")" ]]; then
            base=$(basename "$target")
            rm -f "$css"; touch "$css"
        else
            warn "gtk.css — симлинк вне $GTK4_DIR ($target), не трогаю. Подключите macos-*.css вручную."
            return 0
        fi
    elif [[ -f "$css" ]]; then
        # база, подключённая при прошлом запуске
        base=$(sed -n 's|^@import url("\(gtk-[A-Za-z]*\.css\)"); /\* base \*/$|\1|p' "$css" | head -1)
    fi
    [[ -n "$base" && ! -f "$GTK4_DIR/$base" ]] && base=""

    [[ -n "$base" ]] && imports+="@import url(\"$base\"); /* base */"$'\n'
    for f in "$GTK4_DIR"/macos-*.css; do
        [[ -e "$f" ]] && imports+="@import url(\"$(basename "$f")\");"$'\n'
    done

    tmp=$(mktemp)
    touch "$css"
    # убрать свой блок и блок, который дописывала версия 1.x
    awk -v b="$GTK4_BEGIN" -v e="$GTK4_END" -v lb="$LEGACY_NAUTILUS_BEGIN" -v le="$LEGACY_NAUTILUS_END" '
        $0==b {s=1; next}  $0==e  {s=0; next}
        $0==lb{l=1; next}  $0==le {l=0; next}
        !s && !l' "$css" > "$tmp"

    if [[ -n "$imports" ]]; then
        { printf '%s\n%s%s\n' "$GTK4_BEGIN" "$imports" "$GTK4_END"; cat "$tmp"; } > "$css"
    else
        cat "$tmp" > "$css"
    fi
    rm -f "$tmp"
    # пустой gtk.css не нужен
    [[ -s "$css" ]] || rm -f "$css"
    return 0
}
