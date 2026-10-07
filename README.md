# apcupsd-cgi
Docker - APC UPS Power Management Web Interface (debian:trixie-slim, nginx-light, fcgiwrap, apcupsd-cgi)

# Requirements
This is the APC UPS Power Management Web Interface, so it is necessary to have an [APC UPS](https://www.apc.com/) that supports monitoring (USB cable or network). 
You have to install apcupsd daemon [apcupsd daemon](http://www.apcupsd.org/) in the host machine (if the APC UPS is connected here). For debian/ubuntu:
```
sudo apt install apcupsd
```
If you have connected your APC UPS with a USB cable you can check that it is correctly detected:
```
sudo lsusb
```
You should find a device "American Power Conversion Uninterruptible Power Supply". Edit the file /etc/apcupsd/apcupsd.conf following the guide you find on the official website.
```
sudo nano /etc/apcupsd/apcupsd.conf
```
The minimum parameters to be configured in case of USB connection are the following:
| Parameter | Setting | Notes |
| :----: | --- | ---|
| UPSCABLE | usb | define the type of cable connection |
| UPSTYPE | usb | define the type of UPS |
| DEVICE |  |leave blank for autoconfig usb port| 
| NETSERVER | on | enable network information server|
| NISIP | 0.0.0.0 | IP address on which NIS server will listen for incoming connections|

Now edit /etc/default/apcupsd
```
sudo nano /etc/default/apcupsd
```
ISCONFIGURED=yes

All is done, check the status of daemon 
```
sudo systemctl status apcupsd
```
If the daemon is not running, proceed to enable and start it
```
sudo systemctl enable apcupsd && sudo systemctl start apcupsd
```
check the status of your APC UPS
```
apcaccess status
```

## Docker apcupsd-cgi
The image is based on Debian trixie (slim), with nginx-light as web server, fcgiwrap as CGI server (running as `www-data`) and apcupsd-cgi.

By default apcupsd-cgi connects to the apcupsd daemon on the docker host (the container's default gateway) on the standard port 3551,
so apcupsd on the host must listen on the docker interface too (`NISIP 0.0.0.0`). Opening `/` redirects to `multimon.cgi`.
The container exposes port 80; port 80 on the host is probably already busy, so map it to a free port (I use 4321).

To run the container:
```
docker run -d -p 4321:80 --restart=unless-stopped --name apcupsd-cgi zedred/apcupsd-cgi
```
With Docker Compose (see `docker-compose.yml` in this repository):
```
services:
  apcupsd-cgi:
    image: zedred/apcupsd-cgi
    container_name: apcupsd-cgi
    restart: unless-stopped
    ports:
      - 4321:80
```

### Configuration
| Variable | Default | Notes |
| --- | --- | --- |
| UPS_HOST | docker host (default gateway) | IP/hostname of the machine running apcupsd |
| UPS_PORT | 3551 | apcupsd NIS port |
| UPS_NAME | UPS | name shown in the web interface |

To monitor several UPSes mount your own `hosts.conf`, one `MONITOR host[:port] "name"` line each; it takes precedence over the variables:
```
docker run -d -p 4321:80 -v ./hosts.conf:/etc/apcupsd/hosts.conf:ro --name apcupsd-cgi zedred/apcupsd-cgi
```

### Build your own image
```
git clone https://github.com/zedred79/docker-apcupsd-cgi.git
cd docker-apcupsd-cgi
docker compose up -d --build     # or ./rebuild.sh
```

### Start at boot without a restart policy
`docker-apcupsd-cgi.service` is a systemd unit that starts the existing `apcupsd-cgi` container.
It is not needed if the container uses `--restart=unless-stopped`.

## Usage
Open http://your_host_IP:4321
