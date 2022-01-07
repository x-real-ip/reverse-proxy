# reverse-proxy

[![Build Status](https://drone.theautomation.nl/api/badges/theautomation/reverse-proxy/status.svg)](https://drone.theautomation.nl/theautomation/reverse-proxy)
![GitHub repo size](https://img.shields.io/github/repo-size/theautomation/reverse-proxy?logo=Github)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/theautomation/reverse-proxy?logo=github)
![GitHub last commit (branch)](https://img.shields.io/github/last-commit/theautomation/reverse-proxy/main?logo=github)

[Nginx](https://www.nginx.com/): using this a reverse proxy which takes the client request, passes it on to one or more servers, and subsequently delivers the server's response back to the clients.

[Certbot](https://www.nginx.com/): a free, open source software tool for automatically using Let’s Encrypt certificates on manually-administrated websites and services to enable HTTPS.
If a certificate expires in less than from Let's encrypt defined renewal period, the certificate will be automatically renewed.

## Setup

1. Install [docker-compose](https://docs.docker.com/compose/install/#install-compose).
2. Clone this repository: `git clone https://github.com/theautomation/reverse-proxy.git .`
3. Replace the NGINX config file with yours.
4. Fill in the your variables in "letsencrypt.ini"
5. Run the bash script letsencrypt.sh, it will create a Diffie-Hellman parameter file if it doesn't exist it will fetch certificates based on the configuration file names. Each configuration file with prefix "public_" gets its own certificate. filename must have full domain name between "public_" and ".conf". e.g. public_subdomain.domain.conf.
