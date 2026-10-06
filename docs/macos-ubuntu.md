# macos-ubuntu.sh

Основной скрипт оформления системы.

## Что делает

1. Ставит зависимости через apt (`sassc`, `gnome-shell-extension-user-theme`, `fonts-inter`, `fonts-jetbrains-mono` и др.)
2. Переносит предыдущую установку `WhiteSur*` и текущий `~/.config/gtk-4.0/gtk.css` в `~/backup_themes_ДАТА`
3. Ставит WhiteSur: GTK3/GTK4 (`-l`, для libadwaita), GNOME Shell, иконки, курсоры
4. Ставит San Francisco (или пропускает с `--inter`)
5. Скачивает обои WhiteSur (светлые и тёмные) в `~/.local/share/backgrounds`
6. Ставит Blur My Shell и Dash to Dock с extensions.gnome.org, включает `user-theme`
7. Применяет тему, цветовую схему, акцент, шрифты, кнопки окна слева
8. Настраивает док: внизу, фиксированный, прозрачный, без размытия
9. Собирает `~/.config/gtk-4.0/gtk.css` (WhiteSur + `macos-*.css`)

## Опции

```bash
./scripts/macos-ubuntu.sh --light              # светлый вариант
./scripts/macos-ubuntu.sh --accent purple      # default blue purple pink red orange yellow green grey
./scripts/macos-ubuntu.sh --inter              # Inter вместо SF
./scripts/macos-ubuntu.sh --ubuntu-dock        # оставить встроенный док
./scripts/macos-ubuntu.sh --flatpak --firefox  # тема для Flatpak и Firefox
./scripts/macos-ubuntu.sh --gdm                # тема экрана входа (sudo)
```

Акцент WhiteSur переводится в `accent-color` GNOME: `default` → `blue`, `grey` → `slate`.

## Ключевые пути

| Путь | Содержимое |
|------|------------|
| `~/.themes/WhiteSur-*` | GTK3 и GNOME Shell тема |
| `~/.local/share/icons/WhiteSur*` | Иконки и курсоры |
| `~/.config/gtk-4.0/gtk-Dark.css`, `gtk-Light.css` | WhiteSur для libadwaita |
| `~/.config/gtk-4.0/gtk.css` | Подключает WhiteSur и `macos-*.css` |
| `~/.local/share/fonts/SanFrancisco/` | SF (семейства `SFNS Display`, `SFNS Text`) |
| `~/.local/share/backgrounds/WhiteSur-*.jpg` | Обои |
| `~/macos-setup.log` | Лог |
| `~/backup_themes_*/` | Backup |

## Расширения

| UUID | Источник | Действие |
|------|----------|----------|
| `user-theme@gnome-shell-extensions.gcampax.github.com` | apt | включается |
| `blur-my-shell@aunetx` | extensions.gnome.org | ставится и включается |
| `dash-to-dock@micxgx.gmail.com` | extensions.gnome.org | ставится и включается |
| `ubuntu-dock@ubuntu.com` | система | отключается (если ставится Dash to Dock) |
| `ubuntu-appindicators@ubuntu.com` | система | включается |

Под Wayland новое расширение подхватывается только при следующем входе в сессию, поэтому скрипт пишет UUID прямо в `org.gnome.shell enabled-extensions`.

Ubuntu Dock — форк Dash to Dock с той же схемой `org.gnome.shell.extensions.dash-to-dock`, поэтому настройки дока работают с обоими.

## Тема GDM

WhiteSur рассчитан на GNOME ≤48. Если экран входа выглядит неправильно:

```bash
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme && sudo ./tweaks.sh -g -r
```

## Откат

```bash
./scripts/uninstall.sh --theme
```
