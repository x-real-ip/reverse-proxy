# reverse-proxy

[![Build Status](https://drone.theautomation.nl/api/badges/theautomation/reverse-proxy/status.svg)](https://drone.theautomation.nl/theautomation/reverse-proxy)
![GitHub repo size](https://img.shields.io/github/repo-size/theautomation/reverse-proxy?logo=Github)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/theautomation/reverse-proxy?logo=github)
![GitHub last commit (branch)](https://img.shields.io/github/last-commit/theautomation/reverse-proxy/main?logo=github)

[NGINX](https://www.NGINX.com/): using this a reverse proxy which takes the client request, passes it on to one or more servers, and subsequently delivers the server's response back to the clients.

[Certbot](https://www.NGINX.com/): a free, open source software tool for automatically using Let’s Encrypt certificates on manually-administrated websites and services to enable HTTPS.
If a certificate expires in less than from Let's encrypt defined renewal period, the certificate will be automatically renewed.

## Setup

1. Install [docker-compose](https://docs.docker.com/compose/install/#install-compose).
2. Clone this repository: `git clone https://github.com/theautomation/reverse-proxy.git .`
3. Replace the NGINX config file with yours.
4. Check SSL paths in the NGINX config files

```
    ssl_certificate /etc/letsencrypt/live/myservice.mydomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myservice.mydomain.com/privkey.pem;
```

5. Fill in the your variables in "letsencrypt.ini"
   - `TEST` set this to 1 when testing your configuration it avoid hitting request limits.
   - `EMAIL_ADDRESS` it is recommended that you fill in a email adrress so certbot can automatically send you. [expiration emails](https://letsencrypt.org/docs/expiration-emails/) when your certificate is coming up for renewal.
   - `CONFIG_DIR` Directory where to put your NGINX configuration files.
   - `RSA_KEY_SIZE` leaving this empty will create a 4096 [rsa key size](https://en.wikipedia.org/wiki/Key_size), optionally set it to 2048.
   - `CERTBOT_IMAGE` leaving this empty will use the latest version of the [certbot docker image](https://hub.docker.com/r/certbot/certbot/tags), you can optionally choose a specific docker image version e.g. _certbot/certbot:v1.22.0_
6. Run the bash script letsencrypt.sh.
   - it creates a Diffie-Hellman parameter file if it doesn't exist.
   - it retrieves certificates based on the NGINX configuration filenames. It is important that each NGINX configuration file has a "public\_" prefix followed by a fully qualified domain name (FQDN). letsencrypt.sh looks for these files in the `CONFIG_DIR` and creates a certificate if it doesn't already exist. filename example public_myservice.mydomain.com.conf -> create a myservice.mydomain.com certificate.

## Delete (test)certificate

To replace the test certificate with a real certificate you need to remove it first.
This is needed if you have set (TEST=1 in the ini file)

1. Go to repository directory where docker-compose.yml lives.
2. Change certname in below command and run it.

```bash
docker-compose run --rm --entrypoint "certbot delete --cert-name myservice.mydomain.com" prd-certbot-app
```

3. Enter 'Y' or 'Yes'

## Docker network

The docker-compose.yml specifies the network for NGINX. It is recommended that you place your services that you want to expose to the public internet on the same network as the NGINX container so that the container's hostname can be used and you don't have to expose the port to your docker host. of course you can change the subnet to your needs.

```docker-compose
networks:
  reverse-proxy:
    driver: bridge
    name: reverse-proxy
    ipam:
      config:
        - subnet: 172.22.0.0/16
```
