# pin-login.sh

Вход на экране GDM и разблокировка экрана по короткому PIN вместо пароля. Запускается от root.

```bash
sudo ./scripts/pin-login.sh                 # PIN для текущего пользователя
sudo ./scripts/pin-login.sh --user anna     # для другого пользователя
sudo ./scripts/pin-login.sh --remove        # отключить
```

## Как работает

1. Ставит `libpam-pwdfile` и `apache2-utils`
2. Сохраняет bcrypt-хеш PIN в `/etc/pam-pin/passwd` (`700`/`600`, root)
3. Добавляет в `/etc/pam.d/gdm-password` после `#%PAM-1.0`:
   ```
   auth sufficient pam_pwdfile.so pwdfile=/etc/pam-pin/passwd
   ```
   `sufficient`: верный PIN — вход; неверный — GDM проверяет обычный пароль.

Перед правкой PAM создаётся копия `/etc/pam.d/gdm-password.bak.ДАТА`.

## Ограничения

| Где | Что спрашивается |
|-----|------------------|
| Экран входа GDM | PIN или пароль |
| Экран блокировки GNOME (через GDM, та же служба `gdm-password`) | PIN или пароль |
| sudo, polkit | пароль |
| Связка ключей gnome-keyring | пароль — она зашифрована паролем входа, PIN её не открывает |

Чтобы связка ключей не спрашивала пароль после входа по PIN, можно задать ей пустой пароль в «Пароли и ключи» (Seahorse) — ценой хранения секретов в открытом виде.

PIN короче пароля и уязвимее к подбору. `pam_pwdfile` не ограничивает число попыток — используйте только на устройствах с физическим контролем доступа.

## Если не удаётся войти

Переключитесь в консоль (Ctrl+Alt+F3), войдите по паролю и:

```bash
sudo ./scripts/pin-login.sh --remove
# или вручную
sudo cp /etc/pam.d/gdm-password.bak.ДАТА /etc/pam.d/gdm-password
```
