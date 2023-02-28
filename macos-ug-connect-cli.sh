#!/bin/bash

#Прверяем sudo
if [ "$USER" != "root" ]; then
    echo "Скрипт нужно запустить с sudo"
    exit 1
fi

#Минимизируем ошибки TOTP
echo server 0.ru.pool.ntp.org > /private/etc/ntp.conf
echo server 1.ru.pool.ntp.org >> /private/etc/ntp.conf
launchctl stop system/com.apple.sntpd
launchctl start system/com.apple.sntpd

#Применяем рекомендации ТП UserGate
echo refuse-chap > ~/.ppprc
echo refuse-mschap >> ~/.ppprc
echo refuse-mschap-v2 >> ~/.ppprc

#Прверяем наличие Homebrew
if [[ -z "$(command -v brew)" ]]; then
    echo "Для работы скрипта необходимо установить Homebrew"
    echo "https://brew.sh/"
    echo "Не игнорируй послеустановочные скрипты brew!"
    exit 1
else
    brew update
fi

#Прверяем наличие totp
if [[ -z "$(command -v totp)" ]]; then
    echo "Устанавливаем totp"
    brew install simnalamburt/x/totp
fi

#Прверяем наличие macosvpn
if [[ -z "$(command -v macosvpn)" ]]; then
    echo "Устанавливаем macosvpn"
    brew install macosvpn
fi

#Выясняем переменные
echo -n "Логин: "
read -r login
login="$(tr -d ' ' <<< "$login")"

echo -n "Пароль: "
read -sr password
password="$(tr -d ' ' <<< "$password")"

echo -ne "\nАдрес VPN-сервера: "
read -r server
server="$(tr -d ' ' <<< "$server")"

echo -n "PreSharedSecret: "
read -sr sharedsecret
sharedsecret="$(tr -d ' ' <<< "$sharedsecret")"

echo -ne "\nTOTP: "
read -r totpcode
totpcode="$(tr -d ' ' <<< "$totpcode")"
totpcode="$(tr '[:lower:]' '[:upper:]' <<< "$totpcode")"

#Создаем TOTP генератор
if [[ $(totp list | grep usergate_totp) == "" ]]; then
    totp add usergate_totp <<< "$totpcode" > /dev/null
else
    totp delete usergate_totp > /dev/null
    totp add usergate_totp <<< "$totpcode" > /dev/null
fi


#Создаем запись в «Связке ключей»
if [[ $(security find-generic-password -s "usergate_secret" 2> /dev/null | grep usergate_secret) == "" ]]; then
    security add-generic-password \
    -s "usergate_secret" \
    -a "$login" \
    -w "$password" \
    -j "$sharedsecret" \
    -T "/usr/bin/security"
else
    security delete-generic-password -s "usergate_secret" &> /dev/null
    security add-generic-password \
    -s "usergate_secret" \
    -a "$login" \
    -w "$password" \
    -j "$sharedsecret" \
    -T "/usr/bin/security"
fi

#Создаем VPN-подключение
macosvpn create \
--l2tp "UserGateConnection" \
--endpoint "$server" \
--username "$login" \
--password "$password" \
--sharedsecret "$sharedsecret" \
--force \
> /dev/null

#Создаем скрипт для подключения
echo '#!/bin/bash' > ~/usergateconnect.sh
echo 'user="$(security find-generic-password -s "usergate_secret" | grep acct | cut -c 18- | tr -d \'\"' | tr -d '\' \'')"' >> ~/usergateconnect.sh
echo 'pass="$(security find-generic-password -s "usergate_secret" -w):$(totp get usergate_totp)"' >> ~/usergateconnect.sh
echo 'sec="$(security find-generic-password -s "usergate_secret" | grep icmt | cut -c 18- | tr -d \'\"' | tr -d '\' \'')"' >> ~/usergateconnect.sh
echo 'scutil --nc start "UserGateConnection" --user "$user" --password "$pass" --secret "$sec"' >> ~/usergateconnect.sh

chmod +x ~/usergateconnect.sh

#Делаем алиас
echo 'alias ug=~/usergateconnect.sh' >> ~/.zshrc
source ~/.zshrc

echo "Готово"
echo "Для подключения запусти команду ug"