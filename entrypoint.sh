#!/bin/bash
set -e

HOSTS_CONF=/etc/apcupsd/hosts.conf

# A hosts.conf mounted by the user wins; otherwise build it from the environment
if [ ! -f "$HOSTS_CONF" ]; then
    if [ -z "$UPS_HOST" ]; then
        # default gateway of the container = docker host (read from /proc, no iproute2 needed)
        gw=$(awk '$2 == "00000000" { print $3; exit }' /proc/net/route)
        UPS_HOST=$(printf '%d.%d.%d.%d' 0x${gw:6:2} 0x${gw:4:2} 0x${gw:2:2} 0x${gw:0:2})
    fi
    echo "MONITOR ${UPS_HOST}:${UPS_PORT} \"${UPS_NAME}\"" > "$HOSTS_CONF"
fi
echo "Monitoring:"; grep '^MONITOR' "$HOSTS_CONF"

# fcgiwrap runs the CGI programs as www-data
install -d -o www-data -g www-data /run/fcgiwrap
rm -f /run/fcgiwrap/fcgiwrap.socket
setpriv --reuid=www-data --regid=www-data --init-groups \
    fcgiwrap -c 2 -s unix:/run/fcgiwrap/fcgiwrap.socket &
for _ in $(seq 50); do [ -S /run/fcgiwrap/fcgiwrap.socket ] && break; sleep 0.1; done

exec nginx -g 'daemon off;'
