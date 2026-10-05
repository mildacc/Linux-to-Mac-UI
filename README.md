# Linux-to-Mac-UI

Набор скриптов для оформления **Ubuntu 26.04 LTS (GNOME 50, Wayland)** в стиле macOS.

## Результат

| Компонент | До | После |
|-----------|-----|-------|
| Система | Yaru | WhiteSur (GTK3 + GTK4/libadwaita + GNOME Shell), иконки, курсоры, обои |
| Док | Ubuntu Dock | Dash to Dock внизу, прозрачный |
| Терминал | Ptyxis по умолчанию | zsh + oh-my-posh, MesloLGS NF, автоподсказки и подсветка |
| Файловый менеджер | Nautilus | Вид списком, папки первыми, тёмная боковая панель в стиле Finder |
| Экран входа | Пароль | Вход по PIN (опционально, `pin`) |

## Структура

```
Linux-to-Mac-UI/
├── install.sh               # Установка всех или выбранных компонентов
├── scripts/
│   ├── macos-ubuntu.sh      # Тема, иконки, шрифты, обои, расширения, док
│   ├── terminal-macos.sh    # zsh + oh-my-posh + MesloLGS NF
│   ├── nautilus-macos.sh    # Nautilus в стиле Finder
│   ├── pin-login.sh         # Вход в GDM по PIN (root)
│   ├── uninstall.sh         # Откат
│   └── lib/common.sh        # Общие функции
├── docs/
├── legacy/                  # Старый монолитный скрипт для Ubuntu 24.04
└── CHANGELOG.md
```

## Быстрый старт

```bash
git clone https://github.com/mildacc/Linux-to-Mac-UI.git
cd Linux-to-Mac-UI
./install.sh
```

Затем **выйти из сессии и войти снова** — в 26.04 нет X11, перезапустить оболочку без перелогина нельзя.

> ⚠️ Не запускать от root. Скрипты сами запросят sudo где нужно.

### Выборочно

```bash
./install.sh theme nautilus             # только тема и Nautilus
./install.sh theme -- --light --inter   # опции после «--» уходят скрипту темы
./scripts/terminal-macos.sh --chsh      # каждый скрипт можно запускать отдельно
./install.sh pin                        # вход по PIN (не входит в установку по умолчанию)
```

Тема ставится первой: WhiteSur с флагом `-l` пересоздаёт `~/.config/gtk-4.0/gtk.css`. Если запускаете скрипты по отдельности, а тему переустановили после Nautilus — повторите `nautilus-macos.sh`.

### Опции

| Скрипт | Опция | Действие |
|--------|-------|----------|
| `macos-ubuntu.sh` | `--light` | Светлый вариант |
| | `--accent ЦВЕТ` | `default blue purple pink red orange yellow green grey` |
| | `--inter` | Inter вместо San Francisco |
| | `--ubuntu-dock` | Не ставить Dash to Dock, настроить встроенный док |
| | `--gdm` / `--flatpak` / `--firefox` | Тема WhiteSur для экрана входа / Flatpak / Firefox |
| `terminal-macos.sh` | `--chsh` | Сделать zsh оболочкой входа |
| | `--font-size N` | Размер шрифта (13) |
| | `--opacity 0.9` | Прозрачность профиля Ptyxis |
| | `--no-plugins` | Без zsh-autosuggestions / zsh-syntax-highlighting |
| | `--extras` | eza, bat, fd, ripgrep, fzf + алиасы `open`, `pbcopy`, `pbpaste` |
| `nautilus-macos.sh` | `--no-css` | Только поведение, без собственных стилей |
| | `--admin` | Установить nautilus-admin |
| `pin-login.sh` (sudo) | `--user ИМЯ` | Пользователь (по умолчанию вызвавший sudo) |
| | `--remove` | Отключить вход по PIN |

### Требования

| Требование | Версия |
|------------|--------|
| Ubuntu | 26.04 LTS (на других версиях скрипты предупредят) |
| GNOME Shell | 50 |
| oh-my-posh | актуальная (только для `terminal-macos.sh`), формат темы v4 |

## Откат

```bash
./scripts/uninstall.sh --all        # или --theme / --terminal / --nautilus
./scripts/uninstall.sh --pin        # вход по PIN (в --all не входит)
```

Удаляется только установленное проектом: WhiteSur, SF, обои, Dash to Dock и Blur My Shell, блок в `~/.zshrc`, `macos-nautilus.css`. Изменённые ключи gsettings сбрасываются к умолчаниям. Предыдущие темы — в `~/backup_themes_*`, прежние `.zshrc` и `gtk.css` — в `*.bak.*`.

## Компоненты

| Компонент | Источник |
|-----------|----------|
| WhiteSur GTK тема | [vinceliuice/WhiteSur-gtk-theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) |
| WhiteSur иконки | [vinceliuice/WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme) |
| WhiteSur курсоры | [vinceliuice/WhiteSur-cursors](https://github.com/vinceliuice/WhiteSur-cursors) |
| Обои | [vinceliuice/WhiteSur-wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers) |
| San Francisco | [supermarin/YosemiteSanFranciscoFont](https://github.com/supermarin/YosemiteSanFranciscoFont) (лицензия Apple ограничивает использование вне macOS; альтернатива — `--inter`) |
| Inter, JetBrains Mono | пакеты `fonts-inter`, `fonts-jetbrains-mono` |
| MesloLGS NF | [romkatv/powerlevel10k-media](https://github.com/romkatv/powerlevel10k-media) |
| Blur My Shell | [extensions.gnome.org/3193](https://extensions.gnome.org/extension/3193/blur-my-shell/) |
| Dash to Dock | [extensions.gnome.org/307](https://extensions.gnome.org/extension/307/dash-to-dock/) |

## Известные ограничения

- WhiteSur обрабатывает GNOME ≥48 как 48 — в теме GNOME Shell на GNOME 50 возможны мелкие артефакты. Тему GDM (`--gdm`) ставьте осознанно.
- Snap-приложения (Firefox snap и др.) не видят темы из `~/.themes` и остаются в Yaru.
- Звуковая тема macOS убрана: репозиторий-источник больше недоступен.
- PIN действует только для GDM (вход и разблокировка экрана): sudo и polkit спрашивают пароль, связка ключей после входа по PIN не разблокируется автоматически. Подробнее — [docs/pin-login.md](docs/pin-login.md).

## Ubuntu 24.04

Старый монолитный скрипт (oh-my-zsh + Powerlevel10k, GNOME 46) сохранён в [`legacy/`](legacy/README.md) без поддержки.

## Лицензия

[Apache 2.0](LICENSE)
