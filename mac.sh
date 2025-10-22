#!/bin/bash
set -e

echo "=== 🍎 Полная кастомизация Ubuntu 24.04 под macOS ==="
echo "    Терминал + Интерфейс + Темы"
echo ""

# Очистка от предыдущих запусков
echo "🧹 Очистка временных файлов от предыдущих запусков..."
rm -rf ~/macos-setup ~/blur-my-shell ~/YosemiteSanFranciscoFont ~/WhiteSur-gdm 2>/dev/null || true

# Функции для проверки
check_command() {
    if [ $? -eq 0 ]; then
        echo "✅ $1 выполнено успешно"
    else
        echo "❌ Ошибка при выполнении: $1"
        exit 1
    fi
}

check_url() {
    if wget --spider "$1" 2>/dev/null; then
        return 0
    else
        echo "⚠️  URL недоступен: $1"
        return 1
    fi
}

print_section() {
    echo ""
    echo "[$1] $2"
    echo "$(printf '=%.0s' {1..50})"
}

# === СИСТЕМНЫЕ ЗАВИСИМОСТИ ===
print_section "1/12" "Обновление системы и установка зависимостей"
sudo apt update && sudo apt install -y \
    git curl wget zsh fonts-powerline build-essential \
    neofetch htop tree bat eza fd-find ripgrep fzf tmux \
    gnome-tweaks gnome-shell-extensions \
    gnome-shell-extension-manager chrome-gnome-shell \
    unzip libglib2.0-dev-bin sassc make gettext \
    xclip
check_command "Установка системных зависимостей"

# === OH MY ZSH И ТЕРМИНАЛ ===
print_section "2/12" "Настройка терминала (Oh My Zsh + Powerlevel10k)"

# Установка Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "📦 Установка Oh My Zsh..."
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
fi

# Установка темы Powerlevel10k
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "🎨 Установка темы Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# Установка плагинов для zsh
echo "🔌 Установка плагинов zsh..."
PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-completions" "fast-syntax-highlighting")
repos=("https://github.com/zsh-users/zsh-autosuggestions" 
       "https://github.com/zsh-users/zsh-syntax-highlighting.git" 
       "https://github.com/zsh-users/zsh-completions"
       "https://github.com/zdharma-continuum/fast-syntax-highlighting.git")

for i in "${!plugins[@]}"; do
    if [ ! -d "$PLUGINS_DIR/${plugins[$i]}" ]; then
        git clone "${repos[$i]}" "$PLUGINS_DIR/${plugins[$i]}"
    fi
done

# Создание бэкапа .zshrc
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    echo "📋 Создан бэкап .zshrc"
fi

# Настройка .zshrc
echo "⚙️ Создание конфигурации .zshrc..."
cat > "$HOME/.zshrc" << 'EOF'
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Тема
ZSH_THEME="powerlevel10k/powerlevel10k"

# Плагины
plugins=(
    git sudo docker docker-compose npm node python pip ubuntu
    zsh-autosuggestions zsh-syntax-highlighting zsh-completions
    fast-syntax-highlighting history-substring-search
    colored-man-pages command-not-found extract z
)

source $ZSH/oh-my-zsh.sh

# Пользовательские настройки
export EDITOR='nano'
export BROWSER='firefox'

# Алиасы в стиле macOS
alias ls='exa --icons'
alias ll='exa -la --icons'
alias la='exa -a --icons'
alias lt='exa --tree --icons'
alias cat='batcat'
alias find='fd'
alias grep='rg'
alias top='htop'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias desktop='cd ~/Desktop'
alias downloads='cd ~/Downloads'
alias documents='cd ~/Documents'

# macOS-подобные команды
alias open='xdg-open'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'

# Git алиасы
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Системные алиасы
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias search='apt search'
alias info='apt info'
alias remove='sudo apt remove'
alias autoremove='sudo apt autoremove'

# Функции
mkcd() { mkdir -p "$1" && cd "$1"; }
extract() { 
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# История
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_VERIFY SHARE_HISTORY APPEND_HISTORY INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE

# Автодополнение
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# FZF настройки
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Приветствие
if command -v neofetch &> /dev/null; then
    neofetch
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

check_command "Настройка терминала"

# === НАСТРОЙКА ГОРЯЧИХ КЛАВИШ ТЕРМИНАЛА ===
print_section "3/12" "Настройка горячих клавиш терминала (Ctrl+C/Ctrl+V)"

if command -v gsettings &> /dev/null; then
    # Включение Ctrl+C/Ctrl+V в GNOME Terminal
    gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ copy '<Primary>c'
    gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste '<Primary>v'
    
    # Настройка внешнего вида терминала
    PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
    PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/:${PROFILE}/"
    
    gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" use-system-font false
    gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" font 'MesloLGS NF 12'
    gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" use-theme-colors false
    gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" background-color 'rgb(40,44,52)'
    gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" foreground-color 'rgb(171,178,191)'
    gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" cursor-shape 'block'
    gsettings set "org.gnome.Terminal.Legacy.Profile:${PROFILE_PATH}" cursor-blink-mode 'off'
    
    check_command "Настройка горячих клавиш терминала"
fi

# === УСТАНОВКА ШРИФТОВ ===
print_section "4/12" "Установка шрифтов (Nerd Fonts + San Francisco)"

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Установка Nerd Fonts
echo "🔤 Установка Nerd Fonts..."
nerd_fonts=("Meslo" "FiraCode" "JetBrainsMono" "Hack")
for font in "${nerd_fonts[@]}"; do
    if [ ! -f "$FONT_DIR/${font}*.ttf" ]; then
        echo "Установка шрифта $font..."
        if check_url "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"; then
            wget -qO "/tmp/${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
            unzip -o "/tmp/${font}.zip" -d "$FONT_DIR" >/dev/null 2>&1
            rm "/tmp/${font}.zip"
        fi
    fi
done

# Установка San Francisco шрифтов
echo "🍎 Установка шрифта San Francisco..."
rm -rf ~/macos-setup
mkdir -p ~/macos-setup && cd ~/macos-setup

if git ls-remote https://github.com/supermarin/YosemiteSanFranciscoFont.git &>/dev/null; then
    git clone https://github.com/supermarin/YosemiteSanFranciscoFont.git
    if [ -d "YosemiteSanFranciscoFont" ] && [ "$(ls -A YosemiteSanFranciscoFont/*.ttf 2>/dev/null)" ]; then
        cp YosemiteSanFranciscoFont/*.ttf "$FONT_DIR/"
    fi
fi

fc-cache -fv >/dev/null 2>&1
cd ~
check_command "Установка шрифтов"

# === БЕЗОПАСНАЯ ОЧИСТКА ТЕМ ===
print_section "5/12" "Подготовка к установке тем"

# Создаем backup перед удалением
if [ -d ~/.themes ] || [ -d ~/.icons ]; then
    BACKUP_DIR="~/backup_themes_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    [ -d ~/.themes ] && cp -r ~/.themes "$BACKUP_DIR/" 2>/dev/null || true
    [ -d ~/.icons ] && cp -r ~/.icons "$BACKUP_DIR/" 2>/dev/null || true
    echo "📦 Backup создан в $BACKUP_DIR"
fi

# Безопасное удаление только пользовательских тем
rm -rf ~/.themes ~/.icons
sudo apt install --reinstall yaru-theme-gtk yaru-theme-icon -y
check_command "Подготовка тем"

# === УСТАНОВКА WHITESUR ТЕМ ===
print_section "6/12" "Установка WhiteSur темы, иконок и курсоров"

rm -rf ~/macos-setup
mkdir -p ~/macos-setup && cd ~/macos-setup

# Проверяем доступность репозиториев
whitesur_repos=("https://github.com/vinceliuice/WhiteSur-gtk-theme.git"
                "https://github.com/vinceliuice/WhiteSur-icon-theme.git"
                "https://github.com/vinceliuice/WhiteSur-cursors.git")

for repo in "${whitesur_repos[@]}"; do
    if ! git ls-remote "$repo" &>/dev/null; then
        echo "❌ Репозиторий недоступен: $repo"
        exit 1
    fi
done

echo "📦 Клонирование репозиториев WhiteSur..."
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
git clone https://github.com/vinceliuice/WhiteSur-cursors.git

# Установка тем
cd WhiteSur-gtk-theme && ./install.sh -c dark -t default -N mojave && cd ..
cd WhiteSur-icon-theme && ./install.sh -a && cd ..
cd WhiteSur-cursors && ./install.sh && cd ..

check_command "Установка тем WhiteSur"

# === ОБОИ ===
print_section "7/12" "Установка обоев macOS Catalina"

mkdir -p ~/Pictures
WALLPAPER_URL="https://raw.githubusercontent.com/linuxdotexe/macOS-Catalina-Wallpaper/master/macos-catalina.jpg"

if check_url "$WALLPAPER_URL"; then
    wget -O ~/Pictures/macos-wallpaper.jpg "$WALLPAPER_URL"
    gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/macos-wallpaper.jpg"
    gsettings set org.gnome.desktop.background picture-options "zoom"
    check_command "Установка обоев"
else
    echo "⚠️  Не удалось загрузить обои, используем стандартные"
fi

# === GNOME EXTENSIONS ===
print_section "8/12" "Установка расширений GNOME"

mkdir -p ~/.local/share/gnome-shell/extensions

# Blur My Shell с проверкой
if git ls-remote https://github.com/aunetx/blur-my-shell.git &>/dev/null; then
    cd ~/macos-setup
    git clone https://github.com/aunetx/blur-my-shell.git
    cd blur-my-shell
    if [ -f "Makefile" ] && command -v make &> /dev/null && command -v msgfmt &> /dev/null; then
        echo "🔨 Сборка Blur My Shell..."
        make install
        check_command "Установка Blur My Shell"
    else
        echo "⚠️  Отсутствуют инструменты сборки, пропускаем Blur My Shell"
    fi
    cd ~
else
    echo "⚠️  Репозиторий Blur My Shell недоступен"
fi

# Включение встроенных расширений
gnome-extensions enable ubuntu-appindicators@ubuntu.com 2>/dev/null || echo "⚠️  ubuntu-appindicators не найден"
gnome-extensions enable ubuntu-dock@ubuntu.com 2>/dev/null || echo "⚠️  ubuntu-dock не найден"

check_command "Установка расширений"

# === СИСТЕМНЫЕ ЗВУКИ ===
print_section "9/12" "Установка macOS системных звуков"

mkdir -p ~/.local/share/sounds/macOS
cd ~/.local/share/sounds/macOS

SOUNDS_URL="https://github.com/B00merang-Project/macOS-sounds/archive/refs/heads/master.zip"
if check_url "$SOUNDS_URL"; then
    wget "$SOUNDS_URL" -O sounds.zip
    if [ -f "sounds.zip" ]; then
        unzip -q sounds.zip && mv macOS-sounds-master/* . 2>/dev/null || true
        rm -rf macOS-sounds-master sounds.zip
        gsettings set org.gnome.desktop.sound theme-name "macOS" 2>/dev/null || echo "⚠️  Не удалось установить звуковую тему"
        check_command "Установка звуков"
    fi
else
    echo "⚠️  Не удалось загрузить звуки macOS"
fi
cd ~

# === ПРИМЕНЕНИЕ ТЕМ И ШРИФТОВ ===
print_section "10/12" "Применение тем и шрифтов"

# Применение тем
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark" 2>/dev/null || echo "⚠️  Тема WhiteSur-Dark не найдена"
gsettings set org.gnome.desktop.wm.preferences theme "WhiteSur-Dark" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur" 2>/dev/null || echo "⚠️  Иконки WhiteSur не найдены"
gsettings set org.gnome.desktop.interface cursor-theme "WhiteSur-cursors" 2>/dev/null || echo "⚠️  Курсоры WhiteSur не найдены"

# Применение шрифтов (с fallback на системные)
gsettings set org.gnome.desktop.interface font-name "San Francisco Display 11" 2>/dev/null || gsettings set org.gnome.desktop.interface font-name "Ubuntu 11"
gsettings set org.gnome.desktop.interface document-font-name "San Francisco Text 11" 2>/dev/null || gsettings set org.gnome.desktop.interface document-font-name "Ubuntu 11"
gsettings set org.gnome.desktop.interface monospace-font-name "SF Mono 12" 2>/dev/null || gsettings set org.gnome.desktop.interface monospace-font-name "Ubuntu Mono 13"
gsettings set org.gnome.desktop.wm.preferences titlebar-font "San Francisco Display Bold 11" 2>/dev/null || gsettings set org.gnome.desktop.wm.preferences titlebar-font "Ubuntu Bold 11"

check_command "Применение настроек интерфейса"

# === НАСТРОЙКА ДОКА ===
print_section "11/12" "Настройка дока"

if gsettings list-schemas | grep -q "org.gnome.shell.extensions.dash-to-dock"; then
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
    gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
    gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.35
    gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top false
    gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
    check_command "Настройка дока"
else
    echo "⚠️  Расширение dash-to-dock не найдено"
fi

# === УСТАНОВКА ZSH ПО УМОЛЧАНИЮ ===
print_section "12/12" "Завершение настройки"

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🧩 Установка Zsh по умолчанию..."
    chsh -s $(which zsh)
    echo "⚠️ Необходимо выйти из системы и войти заново для применения shell"
fi

# === ОЧИСТКА И ЗАВЕРШЕНИЕ ===
echo "🧹 Очистка временных файлов..."
rm -rf ~/macos-setup ~/blur-my-shell ~/YosemiteSanFranciscoFont ~/WhiteSur-gdm 2>/dev/null || true

# Создание информационного файла
cat > "$HOME/macos-setup-complete.txt" << 'EOF'
🍎 КАСТОМИЗАЦИЯ UBUNTU ПОД macOS ЗАВЕРШЕНА!

🎨 ИНТЕРФЕЙС:
✅ WhiteSur темы (Dark)
✅ WhiteSur иконки и курсоры  
✅ San Francisco шрифты
✅ macOS Catalina обои
✅ Системные звуки macOS
✅ Настройка дока

💻 ТЕРМИНАЛ:
✅ Oh My Zsh + Powerlevel10k
✅ Плагины: autosuggestions, syntax-highlighting
✅ Nerd Fonts (Meslo, FiraCode, JetBrains Mono, Hack)
✅ Современные утилиты: exa, bat, fd, ripgrep, fzf
✅ Поддержка Ctrl+C/Ctrl+V

🎯 ПОЛЕЗНЫЕ АЛИАСЫ:
• ls, ll, la - красивый вывод файлов
• cat - подсветка синтаксиса  
• open - открыть файл/папку
• pbcopy/pbpaste - копирование в/из буфера
• update - обновить систему
• gs, ga, gc, gp - Git команды

🔧 ЧТО ДЕЛАТЬ ДАЛЬШЕ:
1. Выйти из системы и войти заново
2. Запустить терминал
3. Настроить Powerlevel10k: p10k configure
4. Открыть GNOME Tweaks для тонкой настройки

📝 КОНФИГУРАЦИИ:
• ~/.zshrc - настройки терминала
• ~/.p10k.zsh - настройки темы Powerlevel10k
• Backup старых настроек создан

🆘 ПОМОЩЬ:
• p10k configure - перенастроить тему
• source ~/.zshrc - применить изменения терминала
• gnome-tweaks - настройки интерфейса
EOF

echo ""
echo "🎉 КАСТОМИЗАЦИЯ ПОЛНОСТЬЮ ЗАВЕРШЕНА!"
echo ""
echo "📋 Результат:"
echo "   🎨 Интерфейс в стиле macOS"
echo "   💻 Мощный терминал с Oh My Zsh"
echo "   ⌨️  Поддержка Ctrl+C/Ctrl+V"
echo "   🔤 Nerd Fonts и San Francisco"
echo "   🍎 Звуки и обои macOS"
echo ""
echo "📄 Подробная информация: ~/macos-setup-complete.txt"
echo ""
echo "🔄 ВАЖНО: Выйдите из системы и войдите заново для применения всех изменений!"
echo "⚙️  Дополнительные настройки: GNOME Tweaks"
echo "🎨 Настройка темы терминала: p10k configure"

if [ -d ~/backup_themes_* ]; then
    echo "📦 Backup старых тем сохранен в: ~/backup_themes_*"
fi
