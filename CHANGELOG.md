# Changelog

## [2.1.0] — объединение с Linux-to-Mac-UI

- Проект ubuntu-macos-theme 2.0.0 перенесён в корень репозитория
- `scripts/pin-login.sh` (бывший `setup-pin-gdm.sh`): вход в GDM по PIN
  - PIN передаётся в `htpasswd` через stdin (`-i`), а не аргументом — не виден в `ps`
  - строка PAM вставляется после `#%PAM-1.0`, повтор не дублирует её
  - `--user`, `--remove`; проверка существования пользователя; минимум 4 символа
  - `./install.sh pin`, `./scripts/uninstall.sh --pin`
- `terminal-macos.sh --extras` — из старого `mac.sh`: eza, bat, fd, ripgrep, fzf и алиасы `open`/`pbcopy`/`pbpaste` (через `wl-clipboard`, т.к. X11 в 26.04 нет). `cat`/`find`/`grep` больше не подменяются
- `mac.sh` перенесён в `legacy/mac-24.04.sh` (Ubuntu 24.04, без поддержки)
- Лицензия: Apache 2.0 (как в репозитории)

## [2.0.0] — Ubuntu 26.04 LTS / GNOME 50

Ключи gsettings сверены со схемами пакетов Ubuntu 26.04 (nautilus 50.0, ptyxis 50.1, gnome-shell 50.1, gsettings-desktop-schemas).

### Общее
- `install.sh` — установка всех или выбранных компонентов, проброс опций
- `scripts/uninstall.sh` — откат только того, что ставил проект (`--theme`, `--terminal`, `--nautilus`, `--all`)
- `scripts/lib/common.sh` — общие функции; `gset` не роняет скрипт на отсутствующем ключе
- Проверка версии Ubuntu/GNOME с предупреждением
- Повторный запуск не дублирует блоки в `.zshrc` и `gtk.css` (маркеры начала/конца)
- `set -euo pipefail`, временные файлы удаляются через `trap` даже при ошибке
- CI: ShellCheck + `bash -n` (GitHub Actions)

### macos-ubuntu.sh
- WhiteSur ставится с `-l` — тема применяется и к GTK4/libadwaita-приложениям
- Тема GNOME Shell: включается `user-theme` и задаётся `WhiteSur-Dark`
- `color-scheme` и `accent-color` под выбранный вариант
- Исправлены имена шрифтов SF (`SFNS Display`/`SFNS Text`); наличие проверяется через `fc-list`, запасные — Inter / JetBrains Mono
- Шрифты в `~/.local/share/fonts` вместо устаревшего `~/.fonts`
- Обои из WhiteSur-wallpapers (светлые + тёмные); прежний источник Catalina недоступен
- Звуковая тема macOS удалена — репозиторий-источник недоступен
- Blur My Shell и Dash to Dock ставятся с extensions.gnome.org под текущую версию GNOME и включаются через `enabled-extensions` (активируются после перелогина)
- Настройки Blur My Shell и Dash to Dock пишутся через локальную схему расширения (`--schemadir`)
- Backup и удаление только `WhiteSur*`, остальное в `~/.themes`/`~/.icons` не трогается
- Опции `--light`, `--accent`, `--inter`, `--ubuntu-dock`, `--gdm`, `--flatpak`, `--firefox`
- Убран лишний `gnome-browser-connector` и сборочные пакеты

### terminal-macos.sh
- Шрифт Ptyxis задаётся в `org.gnome.Ptyxis` (в Ptyxis он общий, не в профиле)
- Тема oh-my-posh переведена на формат v4 (`options` вместо устаревшего `properties`)
- Сегмент `exit` заменён на `status` с `always_enabled`: `❯` виден и при коде 0
- Тема проверяется `oh-my-posh print primary` после записи
- В `.zshrc` — блок между маркерами: compinit, история, поиск по ↑/↓, zsh-autosuggestions, zsh-syntax-highlighting (не дублирует уже настроенное вручную)
- Удаляются строки, добавленные версиями 1.x; `.zshrc`-симлинк сохраняется
- Опции `--chsh`, `--font-size`, `--opacity`, `--no-plugins`

### nautilus-macos.sh
- Убраны ключи, которых нет в Nautilus 50 (`start-with-status-bar`, `start-with-sidebar`, `sidebar-width`) — из-за них скрипт падал на шаге 2
- `sort-directories-first` и скрытые файлы — через `org.gtk.gtk4.Settings.FileChooser`
- CSS переписан под селекторы Nautilus 50 (`placessidebar`, `.navigation-sidebar`, `.nautilus-list-view`, `.nautilus-path-button`, `.floating-bar`) и вынесен в `macos-nautilus.css`; все правила ограничены `.nautilus-window`
- Удалён скрипт «Открыть в терминале» — в Nautilus 50 это встроено (Ctrl+.)
- `nautilus-admin` — только по опции `--admin`; `python3-nautilus` больше не нужен

## [1.1.0] — обновление

### macos-ubuntu.sh
- Добавлена установка Dash to Dock вместо ubuntu-dock
- Прозрачный фон дока (иконки прямо на рабочем столе)
- Отключение blur для дока в Blur My Shell
- Кнопки управления окном перенесены влево как в macOS

### nautilus-macos.sh
- Убраны несуществующие пакеты (nautilus-extension-gnome-terminal, gir1.2-nautilus-4.0)
- Рабочий CSS для кнопок управления окном в стиле macOS (GTK4)
- Упрощён CSS боковой панели

## [1.0.0] — начальный релиз

### macos-ubuntu.sh
- WhiteSur GTK тема (dark, mojave)
- WhiteSur иконки и курсоры
- Шрифты San Francisco с fallback на Ubuntu
- Обои macOS Catalina
- Blur My Shell расширение
- Настройка dash-to-dock
- Backup старых тем перед удалением
- Защита от запуска от root
- Лог-файл ~/macos-setup.log

### terminal-macos.sh
- oh-my-posh тема macos.omp.json
- Двухстрочный промпт: путь + git статус + курсор
- Цвет промпта меняется при ошибке
- Шрифт MesloLGS NF
- Автоустановка шрифта в Ptyxis / GNOME Terminal

### nautilus-macos.sh
- Вид список по умолчанию
- Папки первыми, сортировка по имени
- Тёмная боковая панель (GTK CSS)
- Тонкий скроллбар 6px
- Колонки: имя, размер, тип, дата
- Пункт «Открыть в терминале» в контекстном меню
