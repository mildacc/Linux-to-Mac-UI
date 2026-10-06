# nautilus-macos.sh

Nautilus 50 в стиле macOS Finder.

## Что делает

1. Применяет настройки поведения через gsettings
2. Пишет стили в `~/.config/gtk-4.0/macos-nautilus.css` и подключает их в `gtk.css`
3. Удаляет скрипт «Открыть в терминале» из версии 1.x — в Nautilus 50 это встроено
4. Перезапускает Nautilus

## Опции

```bash
./scripts/nautilus-macos.sh --no-css   # только поведение, чистый WhiteSur
./scripts/nautilus-macos.sh --admin    # + nautilus-admin
```

## Настройки gsettings

| Схема | Ключ | Значение |
|-------|------|----------|
| `org.gnome.nautilus.preferences` | `default-folder-viewer` | `list-view` |
| | `default-sort-order` | `name` |
| | `recursive-search`, `show-directory-item-counts` | `local-only` |
| `org.gtk.gtk4.Settings.FileChooser` | `sort-directories-first` | `true` |
| | `show-hidden` | `false` |
| `org.gnome.nautilus.list-view` | `default-zoom-level` | `small` |
| | `default-visible-columns` | имя, размер, тип, дата |
| `org.gnome.nautilus.icon-view` | `default-zoom-level` | `medium` |

Папки первыми и скрытые файлы Nautilus 50 читает из `org.gtk.gtk4.Settings.FileChooser` — это общие настройки с диалогом выбора файлов. Ключей `sidebar-width`, `start-with-sidebar`, `start-with-status-bar` в Nautilus 50 нет.

## GTK CSS

Селекторы сверены с исходниками Nautilus 50:

| Элемент | Селектор |
|---------|----------|
| Боковая панель | `placessidebar`, `.navigation-sidebar > row` |
| Список файлов | `.nautilus-list-view columnview > listview > row` |
| Сетка | `.nautilus-grid-view gridview > child` |
| Заголовки колонок | `columnview > header > button` |
| Строка пути | `.nautilus-path-button`, `.current-dir` |
| Строка состояния | `.floating-bar` |

Все правила ограничены `.nautilus-window` и не влияют на другие приложения. Проверить или подобрать селектор:

```bash
GTK_DEBUG=interactive nautilus
```

Свои правки держите в отдельном файле `~/.config/gtk-4.0/macos-ЧТО-УГОДНО.css` — он подключится при следующем запуске любого скрипта.

## Горячие клавиши

| Клавиши | Действие |
|---------|----------|
| Ctrl+. | Открыть терминал в текущей папке |
| Ctrl+H | Скрытые файлы |
| Ctrl+L | Ввод пути |
| Ctrl+1 / Ctrl+2 | Список / сетка |

## Ключевые пути

| Путь | Содержимое |
|------|------------|
| `~/.config/gtk-4.0/macos-nautilus.css` | Стили |
| `~/.config/gtk-4.0/gtk.css` | Подключение стилей |
| `~/nautilus-setup.log` | Лог |

## Откат

```bash
./scripts/uninstall.sh --nautilus
```
