# Полезные команды и настройки

Всё что было настроено вручную в процессе — для быстрого применения или справки.

## Dok панель

```bash
# Прозрачный фон
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode  'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock customize-alphas   true
gsettings set org.gnome.shell.extensions.dash-to-dock min-alpha          0.0
gsettings set org.gnome.shell.extensions.dash-to-dock max-alpha          0.0
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.0

# Отключить blur для дока (Blur My Shell)
gsettings --schemadir ~/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas \
    set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur false

# Intellihide — прятаться только когда окно перекрывает dok
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed      false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide      true
gsettings set org.gnome.shell.extensions.dash-to-dock autohide         true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'FOCUS_APPLICATION_WINDOWS'
# Режимы: FOCUS_APPLICATION_WINDOWS | MAXIMIZED_WINDOWS | ALL_WINDOWS | ALWAYS_ON_TOP

# Позиция дока
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
```

## Кнопки управления окном

```bash
# Слева как в macOS
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# Справа как в Windows
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
```

## GTK CSS — кнопки окна в стиле macOS

WhiteSur уже рисует кнопки в стиле macOS. Этот CSS нужен, только если хотите свои цвета/размеры.
Сохраните его в отдельный файл — скрипты сами подключат его в `gtk.css`:

```bash
nano ~/.config/gtk-4.0/macos-windowcontrols.css
./scripts/nautilus-macos.sh   # пересоберёт gtk.css (macos-ubuntu.sh тоже)
```


```css
/* macOS-style window buttons (GTK4) */
headerbar {
    min-height: 32px;
    padding: 0;
}

windowcontrols > button {
    min-width: 16px;
    min-height: 16px;
    margin: 0 4px;
    padding: 0;
    border-radius: 999px;
    border: none;
    box-shadow: none;
}

windowcontrols button image {
    opacity: 0;
    -gtk-icon-size: 16px;
    transform: scale(1.3);
}

windowcontrols > button.close    image { color: #000; }
windowcontrols > button.minimize image { color: #000; }
windowcontrols > button.maximize image { color: #000; }

windowcontrols > button:hover image {
    opacity: 1;
}

headerbar windowcontrols {
    margin-top: 8px;
    margin-bottom: 8px;
}

windowcontrols > button.close    { background-color: #FF5F57; }
windowcontrols > button.minimize { background-color: #FFBD2E; }
windowcontrols > button.maximize { background-color: #28C841; }

windowcontrols > button.close:hover    { background-color: #FF3B30; }
windowcontrols > button.minimize:hover { background-color: #FFB000; }
windowcontrols > button.maximize:hover { background-color: #00C425; }
```

## Иконки

```bash
# Применить WhiteSur (установлен скриптом)
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur"

# Установить и применить Tela (альтернатива, цветные)
git clone --depth=1 https://github.com/vinceliuice/Tela-icon-theme.git /tmp/tela
/tmp/tela/install.sh -a
gsettings set org.gnome.desktop.interface icon-theme "Tela-dark"
```

## Шрифты

```bash
# San Francisco (установлен скриптом; имена семейств — SFNS Display / SFNS Text)
gsettings set org.gnome.desktop.interface font-name            "SFNS Display 11"
gsettings set org.gnome.desktop.interface document-font-name   "SFNS Text 11"
gsettings set org.gnome.desktop.wm.preferences titlebar-font   "SFNS Display Bold 11"

# Свободная альтернатива
gsettings set org.gnome.desktop.interface font-name            "Inter 11"
gsettings set org.gnome.desktop.interface monospace-font-name  "JetBrains Mono 11"

# Проверить, что шрифт реально установлен (gsettings примет любую строку)
fc-list -q "SFNS Display" && echo есть || echo нет

# Сбросить на стандартные Ubuntu
gsettings reset org.gnome.desktop.interface font-name
gsettings reset org.gnome.desktop.interface document-font-name
gsettings reset org.gnome.desktop.interface monospace-font-name
gsettings reset org.gnome.desktop.wm.preferences titlebar-font
```

## Обои

```bash
gsettings set org.gnome.desktop.background picture-uri      "file://$HOME/.local/share/backgrounds/WhiteSur-light.jpg"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/backgrounds/WhiteSur-dark.jpg"
gsettings set org.gnome.desktop.background picture-options  "zoom"
```

Другие варианты (Monterey, Ventura, Sonoma) — в [WhiteSur-wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers/tree/main/4k).

## Цвет и акцент

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'   # prefer-light | default
gsettings set org.gnome.desktop.interface accent-color 'blue'          # blue teal green yellow orange red pink purple slate
```

## Расширения

```bash
gnome-extensions list --enabled
gsettings get org.gnome.shell enabled-extensions
gsettings get org.gnome.shell disabled-extensions
```

Под Wayland (единственная сессия в 26.04) новое расширение подхватывается только после выхода и входа.

## Nautilus

```bash
# Скрытые файлы / папки первыми — общие настройки GTK4 (ключ show-hidden-files в Nautilus устарел)
gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true

# Сбросить настройки Nautilus
gsettings reset-recursively org.gnome.nautilus.preferences
gsettings reset-recursively org.gnome.nautilus.list-view
gsettings reset-recursively org.gnome.nautilus.icon-view

# Отладка CSS
GTK_DEBUG=interactive nautilus
```

## oh-my-posh

```bash
exec zsh                                    # применить тему без перезапуска терминала
oh-my-posh print primary --config ~/.config/oh-my-posh/macos.omp.json --shell zsh   # проверить тему
oh-my-posh upgrade                          # обновить oh-my-posh
```

## Терминал — автокомплит и история

Ставится и настраивается `terminal-macos.sh` (блок `ubuntu-macos-theme` в `~/.zshrc`):

- `zsh-autosuggestions` — серая подсказка из истории, принять по → или End
- `zsh-syntax-highlighting` — подсвечивает команды зелёным/красным в реальном времени
- ↑/↓ — поиск по истории по введённому началу

Если `.zshrc` уже содержит эти настройки (например, после oh-my-zsh), скрипт их не дублирует.

## Откат

```bash
./scripts/uninstall.sh --all          # или --theme / --terminal / --nautilus

# Резервные копии
ls -d ~/backup_themes_*               # прежние WhiteSur и gtk.css
ls ~/.zshrc.bak.* ~/.config/gtk-4.0/gtk.css.bak.*
```
