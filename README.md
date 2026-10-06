# Linux-to-Mac-UI

Скрипты, которые за один запуск оформляют **Ubuntu 26.04 LTS (GNOME 50, Wayland)** в стиле macOS: тема WhiteSur, док внизу, кнопки окна слева, шрифт San Francisco, терминал с промптом в духе macOS, Nautilus в стиле Finder и (по желанию) вход по PIN.

Всё ставится в домашний каталог пользователя, повторный запуск безопасен, любой компонент откатывается отдельной командой.

## Содержание

- [Что меняется](#что-меняется)
- [Требования](#требования)
- [Установка](#установка)
- [Опции](#опции)
- [Откат](#откат)
- [Решение проблем](#решение-проблем)
- [Структура проекта](#структура-проекта)
- [Источники](#источники)
- [Известные ограничения](#известные-ограничения)

## Что меняется

| Компонент | Было | Станет | Скрипт |
|-----------|------|--------|--------|
| Тема | Yaru | WhiteSur: GTK3, GTK4/libadwaita, GNOME Shell; иконки, курсоры, обои (светлые + тёмные) | `macos-ubuntu.sh` |
| Шрифты | Ubuntu Sans | San Francisco (или Inter с `--inter`), моноширинный — JetBrains Mono | `macos-ubuntu.sh` |
| Окна | Кнопки справа | Кнопки «закрыть / свернуть / развернуть» слева | `macos-ubuntu.sh` |
| Док | Ubuntu Dock слева | Dash to Dock внизу, фиксированный, прозрачный; Blur My Shell для панели и обзора | `macos-ubuntu.sh` |
| Терминал | bash | zsh + oh-my-posh, шрифт MesloLGS NF, автоподсказки, подсветка, поиск по истории ↑/↓ | `terminal-macos.sh` |
| Файлы | Nautilus по умолчанию | Вид списком, папки первыми, колонки как в Finder, тёмная боковая панель | `nautilus-macos.sh` |
| Вход | Пароль | PIN на экране входа GDM (только по запросу) | `pin-login.sh` |

Промпт терминала:

```
 ~/Projects  main ±
❯
```

## Требования

| | |
|-|-|
| ОС | Ubuntu 26.04 LTS. На других версиях скрипты предупредят и продолжат, часть ключей gsettings может не найтись |
| Оболочка | GNOME Shell 50, сессия Wayland |
| Права | Обычный пользователь с sudo. **Не запускайте от root** — gsettings работают только в сессии пользователя |
| Сеть | Доступ к github.com, extensions.gnome.org, raw.githubusercontent.com |
| oh-my-posh | Только для терминала. Установка: `curl -s https://ohmyposh.dev/install.sh \| bash -s` |

## Установка

```bash
git clone https://github.com/mildacc/Linux-to-Mac-UI.git
cd Linux-to-Mac-UI

# для терминала нужен oh-my-posh (один раз)
curl -s https://ohmyposh.dev/install.sh | bash -s

./install.sh
```

После завершения **выйдите из сессии и войдите снова**. В 26.04 нет X11, поэтому GNOME Shell нельзя перезапустить на лету: новые расширения и тема оболочки применяются только при следующем входе.

Каждый скрипт пишет лог в домашний каталог: `~/macos-setup.log`, `~/terminal-setup.log`, `~/nautilus-setup.log`.

### Выборочная установка

```bash
./install.sh theme                       # только оформление системы
./install.sh terminal nautilus           # только терминал и Nautilus
./install.sh theme -- --light --inter    # всё после «--» передаётся скрипту темы
./install.sh pin                         # вход по PIN (в установку по умолчанию не входит)
```

Скрипты можно запускать и напрямую, справка — `--help`:

```bash
./scripts/macos-ubuntu.sh --accent purple --flatpak
./scripts/terminal-macos.sh --chsh --extras
./scripts/nautilus-macos.sh --no-css
sudo ./scripts/pin-login.sh
```

> Тема ставится первой: WhiteSur с флагом `-l` пересоздаёт `~/.config/gtk-4.0/gtk.css`. `install.sh` соблюдает порядок сам. Если вы переустановили тему отдельно после Nautilus — запустите `nautilus-macos.sh` ещё раз.

## Опции

### `macos-ubuntu.sh` — оформление

| Опция | Действие |
|-------|----------|
| `--light` | Светлый вариант (по умолчанию тёмный) |
| `--accent ЦВЕТ` | `default` `blue` `purple` `pink` `red` `orange` `yellow` `green` `grey` |
| `--inter` | Inter вместо San Francisco (свободная лицензия) |
| `--ubuntu-dock` | Не ставить Dash to Dock, настроить встроенный Ubuntu Dock |
| `--gdm` | Тема WhiteSur для экрана входа (sudo; рассчитана на GNOME ≤48) |
| `--flatpak` | Тема для Flatpak-приложений |
| `--firefox` | Тема для Firefox (не snap) |

### `terminal-macos.sh` — терминал

| Опция | Действие |
|-------|----------|
| `--chsh` | Сделать zsh оболочкой входа |
| `--font-size N` | Размер шрифта, по умолчанию 13 |
| `--opacity 0.92` | Прозрачность профиля Ptyxis |
| `--no-plugins` | Без zsh-autosuggestions и zsh-syntax-highlighting |
| `--extras` | eza, bat, fd, ripgrep, fzf и алиасы `ls`/`ll`/`lt`, `open`, `pbcopy`, `pbpaste` |

### `nautilus-macos.sh` — файловый менеджер

| Опция | Действие |
|-------|----------|
| `--no-css` | Только настройки поведения, без собственных стилей |
| `--admin` | Установить nautilus-admin («Открыть как администратор») |

### `pin-login.sh` — вход по PIN (через sudo)

| Опция | Действие |
|-------|----------|
| `--user ИМЯ` | Пользователь; по умолчанию тот, кто вызвал sudo |
| `--remove` | Удалить PIN и строку из PAM |

PIN принимают экран входа и экран блокировки GNOME. sudo, polkit и связка ключей по-прежнему спрашивают пароль. Подробности и аварийный откат — в [docs/pin-login.md](docs/pin-login.md).

## Откат

```bash
./scripts/uninstall.sh --all          # тема + терминал + Nautilus
./scripts/uninstall.sh --theme        # или по отдельности: --terminal, --nautilus
./scripts/uninstall.sh --pin          # вход по PIN (в --all не входит)
```

Удаляется только то, что ставил проект: WhiteSur, шрифты SF, обои, Dash to Dock и Blur My Shell, блок в `~/.zshrc`, `macos-nautilus.css`. Изменённые ключи gsettings сбрасываются к умолчаниям, Ubuntu Dock включается обратно.

Резервные копии:

| Что | Где |
|-----|-----|
| Прежние темы WhiteSur и `gtk.css` | `~/backup_themes_ДАТА/` |
| `~/.zshrc`, `gtk.css`, тема oh-my-posh | рядом, с суффиксом `.bak.ДАТА` |
| `/etc/pam.d/gdm-password` | `/etc/pam.d/gdm-password.bak.ДАТА` |

## Решение проблем

| Симптом | Причина и решение |
|---------|-------------------|
| Док и размытие не появились | Расширения применяются после перелогина. Проверить: `gnome-extensions list --enabled` |
| «нет версии для GNOME 50 на extensions.gnome.org» | Расширение ещё не обновлено под вашу версию GNOME. Поставьте через «Менеджер расширений» позже или используйте `--ubuntu-dock` |
| Приложения GTK4 (Настройки, Nautilus) остались в Adwaita | Перезапустите приложение. Проверьте, что `~/.config/gtk-4.0/gtk.css` содержит `@import` WhiteSur |
| Вместо иконок в промпте квадраты | В терминале не выбран шрифт MesloLGS NF: выберите его вручную или перезапустите `terminal-macos.sh` |
| «oh-my-posh не найден» | Установите: `curl -s https://ohmyposh.dev/install.sh \| bash -s`, затем откройте новый терминал |
| Firefox / другие snap-приложения не в теме | Snap не видит `~/.themes` — это ограничение snap |
| Экран входа выглядит неправильно после `--gdm` | `git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git && cd WhiteSur-gtk-theme && sudo ./tweaks.sh -g -r` |
| Не получается войти после настройки PIN | Ctrl+Alt+F3, войдите по паролю, `sudo ./scripts/pin-login.sh --remove` |

Подбор CSS-селекторов для Nautilus: `GTK_DEBUG=interactive nautilus`. Готовые команды для ручной настройки дока, шрифтов, обоев — в [docs/tips.md](docs/tips.md).

## Структура проекта

```
Linux-to-Mac-UI/
├── install.sh               # установка всех или выбранных компонентов
├── scripts/
│   ├── macos-ubuntu.sh      # тема, иконки, шрифты, обои, расширения, док
│   ├── terminal-macos.sh    # zsh + oh-my-posh + MesloLGS NF
│   ├── nautilus-macos.sh    # Nautilus в стиле Finder
│   ├── pin-login.sh         # вход в GDM по PIN (root)
│   ├── uninstall.sh         # откат
│   └── lib/common.sh        # общие функции: gsettings, расширения, блоки в файлах
├── docs/                    # подробное описание каждого скрипта и полезные команды
├── legacy/                  # старый скрипт для Ubuntu 24.04 (без поддержки)
└── CHANGELOG.md
```

Документация по скриптам:
[macos-ubuntu](docs/macos-ubuntu.md) ·
[terminal-macos](docs/terminal-macos.md) ·
[nautilus-macos](docs/nautilus-macos.md) ·
[pin-login](docs/pin-login.md) ·
[tips](docs/tips.md)

Проверка кода (то же самое делает CI):

```bash
shellcheck -x -S warning install.sh scripts/*.sh scripts/lib/*.sh
for f in install.sh scripts/*.sh scripts/lib/*.sh; do bash -n "$f"; done
```

## Источники

| Компонент | Откуда |
|-----------|--------|
| WhiteSur: тема, иконки, курсоры, обои | [vinceliuice/WhiteSur-gtk-theme](https://github.com/vinceliuice/WhiteSur-gtk-theme), [-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme), [-cursors](https://github.com/vinceliuice/WhiteSur-cursors), [-wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers) |
| San Francisco | [supermarin/YosemiteSanFranciscoFont](https://github.com/supermarin/YosemiteSanFranciscoFont) — лицензия Apple ограничивает использование вне macOS; свободная альтернатива — `--inter` |
| Inter, JetBrains Mono | пакеты Ubuntu `fonts-inter`, `fonts-jetbrains-mono` |
| MesloLGS NF | [romkatv/powerlevel10k-media](https://github.com/romkatv/powerlevel10k-media) |
| Blur My Shell, Dash to Dock | [extensions.gnome.org/3193](https://extensions.gnome.org/extension/3193/blur-my-shell/), [extensions.gnome.org/307](https://extensions.gnome.org/extension/307/dash-to-dock/) |
| oh-my-posh | [ohmyposh.dev](https://ohmyposh.dev) |

## Известные ограничения

- WhiteSur обрабатывает GNOME ≥48 как 48 — в теме GNOME Shell на GNOME 50 возможны мелкие артефакты.
- Snap-приложения не видят темы из `~/.themes` и остаются в Yaru.
- Звуковой темы macOS нет: репозиторий-источник больше недоступен.
- После входа по PIN связка ключей не разблокируется автоматически и попросит пароль.

### Ubuntu 24.04

Первая версия — монолитный скрипт с oh-my-zsh и Powerlevel10k — лежит в [`legacy/`](legacy/README.md). Она не поддерживается и удаляет весь `~/.themes`; прочитайте предупреждение перед запуском.

## Лицензия

[Apache 2.0](LICENSE)
