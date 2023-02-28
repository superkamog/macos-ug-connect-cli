# macos-ug-connect-cli
Автоматизация VPN-подключения с TOTP к UserGate для MacOS.
Все данные для покдлючения хранятся во встроенном MacOS keychain.
## Установка
```
curl -fsSL https://github.com/superkamog/macos-ug-connect-cli/releases/download/v1.0.0/macos-ug-connect-cli.sh > ~/macos-ug-connect-cli.sh
chmod +x ~/macos-ug-connect-cli.sh
./macos-ug-connect-cli.sh
```
Для работы скрипта необходим [Homebrew](https://github.com/Homebrew/install), [macos-totp-cli](https://github.com/simnalamburt/macos-totp-cli) и [macosvpn](https://github.com/halo/macosvpn).

Не игнорируйте послеуcтановочные скрипты Homebrew.

## Запуск
После запуска скрипта он попросит у вас данные:
1. Логин - логин для подключения
2. Пароль - пароль для подключения
3. Адрес VPN-сервера - доменное имя или ip-адрес, к которому будет производиться подключение
4. PreSharedSecret -  pre-shared key для аутентификации
5. TOTP - код для генерации TOTP полученынй на портале USerGate