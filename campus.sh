#!/bin/sh

encodeURI() {
    echo $(echo -ne "$1" | hexdump -v -e '/1 "%02x"' | sed 's/\(..\)/%\1/g')
}

LOGIN=$(encodeURI $1)
PASSWORD=$(encodeURI $2)

COOKIES="/tmp/cookies.txt"

UA="Mozilla/5.0 (X11; Linux x86_64; rv:62.0) Gecko/20100101 Firefox/62.0"

PORTAL_URL="https://connect.wifirst.net/?perform=true"
CONNECT_URL="https://smartcampus.wifirst.net/sessions"
PRIV_CONNECT_URL="https://wireless.wifirst.net:8090/goform/HtmlLoginRequest"

TOKEN_RGX="s/^.*authenticity_token.*value=\"\(.*\)\" \/><\/div>/\1/p"
USERNAME_RGX="s/^.*username.*value=\"\(.*\)\" \/>/\1/p"
PASSWORD_RGX="s/^.*password.*value=\"\(.*\)\" \/>/\1/p"

if [ -z "$LOGIN" ] || [ -z "$PASSWORD" ]; then
	echo "Usage: /bin/sh wifirst-autologin.sh LOGIN PASSWORD"
	exit 1
fi

PORTAL_RESP=$(wget -qO- $PORTAL_URL \
        --load-cookies $COOKIES \
        --save-cookies $COOKIES \
        --keep-session-cookies \
        --header "User-Agent: $UA")

CSRF_TOKEN=$(encodeURI $(echo "$PORTAL_RESP" | sed -n "$TOKEN_RGX"))

CONNECT_RESP=$(wget -qO- $CONNECT_URL \
        --load-cookies $COOKIES \
        --save-cookies $COOKIES \
        --keep-session-cookies \
        --header "User-Agent: $UA" \
        --post-data "utf8=%26%23x2713%3B&authenticity_token=$CSRF_TOKEN&login=$LOGIN&password=$PASSWORD")

PRIV_USERNAME=$(encodeURI $(echo "$CONNECT_RESP" | sed -n "$USERNAME_RGX"))
PRIV_PASSWORD=$(encodeURI $(echo "$CONNECT_RESP" | sed -n "$PASSWORD_RGX"))

D1="commit=Se%20connecter"
D2="username=$PRIV_USERNAME"
D3="password=$PRIV_PASSWORD"
D4="qos_class="
D5="success_url=https%3A%2F%2Fapps.wifirst.net%2F%3Fredirected%3Dtrue"
D6="error_url=https%3A%2F%2Fconnect.wifirst.net%2Flogin_error"

wget -qO /dev/null $PRIV_CONNECT_URL \
    --load-cookies $COOKIES \
    --save-cookies $COOKIES \
    --keep-session-cookies \
    --header "User-Agent: $UA" \
    --post-data "$D1&$D2&$D3&$D4&$D5&$D6"

rm $COOKIES
