#!/bin/bash
# Script written by Coen Stam
#
# This sets up Let's Encrypt SSL certificates and automatic renewal 
# using certbot: https://certbot.eff.org
#
# Certificate files are placed into subdirectories under
# /etc/letsencrypt/live/*.
# 
# A certificate will be created or renewed if it have a prefix "public." in config filename.
#

set -e

# Email address for Certbot
email_address="c.stam.mail@gmail.com"

# Domain e.g. "mydomain.com"
domain="theautomation.nl"

# Directory where NGINX config files lives
config_dir="./nginx/conf/public.*"

# RSA key size
rsa_key_size=2048

# Certbot options
options=(
    "--dry-run"
    "--webroot"
    "--webroot-path=/var/www/certbot/"
    "--email $email_address"
    "--agree-tos"
    "--no-eff-email"
    "--rsa-key-size $rsa_key_size"
    "--keep-until-expiring"
    )

# Check if docker-compose is installed
if ! [ -x "$(command -v docker-compose)" ]
then
    echo "Error: docker-compose is not installed." >&2
    
fi

# Check if docker-compose file exists
if [ ! -f ./docker-compose.yml ]
then
    echo "docker-compose.yml not found"
    exit 1
fi

# Check Diffie-Hellman parameter
if [ ! -f ./certbot/conf/dhparams/dhparam.pem ]
then
    sudo mkdir -p ./certbot/conf/dhparams/
    docker-compose run --rm --entrypoint \
    "openssl dhparam -out /etc/letsencrypt/dhparams/dhparam.pem $rsa_key_size" prd-certbot-app
fi

# Create dummy certificates if it doesn't exists.
for file in $config_dir
do
    subdomain=$(basename $file | sed -e 's/public.\(.*\).conf/\1/')
    if [ ! -f ./certbot/conf/renewal/$subdomain.$domain.conf ]
    then
    echo "Creating dummy certificates for $subdomain.$domain"
    sudo mkdir -p ./certbot/conf/live/$subdomain.$domain
    docker-compose run --rm --entrypoint \
    "openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1 \
        -keyout '/etc/letsencrypt/live/$subdomain.$domain/privkey.pem' \
        -out '/etc/letsencrypt/live/$subdomain.$domain/fullchain.pem' \
        -subj '/CN=localhost'" prd-certbot-app
    fi
done

# Start nginx
docker-compose run --rm prd-nginx-app 

# Deleting dummy files
for file in $config_dir
do
    subdomain=$(basename $file | sed -e 's/public.\(.*\).conf/\1/')
    if [ ! -f ./certbot/conf/renewal/$subdomain.$domain.conf ]
    then
    echo "Deleting dummy certificates for $subdomain.$domain"
    sudo rm -r ./certbot/conf/live/$subdomain.$domain
    fi
done

# Create certificate if it doesn't exist or renew if needed
for file in $config_dir
do
    subdomain=$(basename $file | sed -e 's/public.\(.*\).conf/\1/')
    docker-compose run --rm prd-certbot-app certonly ${options[@]} -d $subdomain.$domain
done

# Reload nginx if config syntax is ok
echo "Starting nginx"
docker exec -it prd-nginx-app bash -c "nginx -t && nginx -s reload"
