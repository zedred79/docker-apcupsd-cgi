# APC UPS Power Management Web Interface (debian:trixie-slim, nginx-light, fcgiwrap, apcupsd-cgi)
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx-light fcgiwrap apcupsd-cgi \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/apcupsd/hosts.conf \
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

# UPS_HOST: apcupsd NIS host to monitor (default: the docker host, i.e. the container's default gateway)
ENV UPS_HOST="" \
    UPS_PORT=3551 \
    UPS_NAME="UPS"

EXPOSE 80

HEALTHCHECK --interval=60s --timeout=5s --start-period=10s \
  CMD bash -c 'exec 3<>/dev/tcp/127.0.0.1/80 && printf "GET /multimon.cgi HTTP/1.0\r\n\r\n" >&3 && grep -q "200 OK" <&3'

ENTRYPOINT ["/entrypoint.sh"]
