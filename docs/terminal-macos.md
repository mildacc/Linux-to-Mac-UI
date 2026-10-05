# terminal-macos.sh

Настройка терминала: zsh + oh-my-posh + MesloLGS NF.

## Требования

- `oh-my-posh` в PATH: `curl -s https://ohmyposh.dev/install.sh | bash -s`
- zsh и плагины скрипт поставит сам

## Что делает

1. Ставит `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting` (если их нет)
2. Скачивает MesloLGS NF в `~/.local/share/fonts/MesloLGS/`
3. Пишет тему `~/.config/oh-my-posh/macos.omp.json` (формат v4) и проверяет её через `oh-my-posh print primary`
4. Добавляет в `~/.zshrc` блок между маркерами `# >>> ubuntu-macos-theme >>>` … `# <<< ubuntu-macos-theme <<<`
5. Задаёт шрифт в Ptyxis (`org.gnome.Ptyxis font-name`) или GNOME Terminal

## Опции

```bash
./scripts/terminal-macos.sh --chsh          # zsh как оболочка входа
./scripts/terminal-macos.sh --font-size 14
./scripts/terminal-macos.sh --opacity 0.92  # прозрачность профиля Ptyxis
./scripts/terminal-macos.sh --no-plugins
```

### --extras

Ставит `eza bat fd-find ripgrep fzf wl-clipboard xdg-utils` и добавляет в блок `.zshrc`:

| Алиас | Команда |
|-------|---------|
| `ls`, `ll`, `lt` | `eza` с иконками, `ll` — со статусом git, `lt` — дерево 2 уровня |
| `bat`, `fd` | `batcat`, `fdfind` (так они называются в Ubuntu) |
| `open` | `xdg-open` |
| `pbcopy`, `pbpaste` | `wl-copy`, `wl-paste` |

Плюс привязки fzf: Ctrl+R — история, Ctrl+T — файл, Alt+C — перейти в каталог. Стандартные `cat`, `find`, `grep` не подменяются — скрипты и привычные флаги продолжают работать.

## Блок в .zshrc

- `compinit` с выбором из меню и автодополнением без учёта регистра
- История 10 000 строк, общая между вкладками, без дублей
- ↑/↓ — поиск по истории по введённому началу
- oh-my-posh
- zsh-autosuggestions, zsh-syntax-highlighting (последним)

Что уже настроено в `.zshrc` вне блока (история, compinit, oh-my-zsh, плагины) — не дублируется. Повторный запуск заменяет блок, а не дописывает.

## Промпт

```
 ~/Projects  main ±
❯
```

Первая строка: иконка · путь · git ветка · статус изменений · версии node/python (если в каталоге есть их файлы).
Вторая строка: `❯` — зелёный, красный при ненулевом коде возврата.

## Цвета

| Элемент | Цвет |
|---------|------|
| Иконка Apple | `#6E9FE0` |
| Путь | `#C5C8C6` |
| Git чистый | `#A8CC8C` |
| Git working changes | `#F0C27F` |
| Git staged changes | `#E06C75` |
| Node / Python версия | `#6EBF87` |

## Ключевые пути

| Путь | Содержимое |
|------|------------|
| `~/.config/oh-my-posh/macos.omp.json` | Тема |
| `~/.local/share/fonts/MesloLGS/` | Шрифт |
| `~/.zshrc.bak.*` | Backup |
| `~/terminal-setup.log` | Лог |

## Откат

```bash
./scripts/uninstall.sh --terminal
```
