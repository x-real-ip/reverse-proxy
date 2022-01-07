#!/bin/bash
# Script written by Coen Stam
#
# This sets up Let's Encrypt SSL certificates and automatic renewal
# using certbot: https://certbot.eff.org
#
# Certificate files are placed into subdirectories under
# /etc/letsencrypt/live/*.
#
# A certificate will be created or renewed if it have a prefix "public_" in config filename.
#

set -e

# Include ini
source "${PWD}"/letsencrypt.ini

# Check if docker-compose is installed
if ! [ -x "$(command -v docker-compose)" ]; then echo "### Error: docker-compose is not installed ..." exit 1 >&2; fi

# Check if docker-compose file exists
if [ ! -f "${PWD}"/docker-compose.yml ]; then echo "### Error: docker-compose.yml not found ..." exit 1; fi

# Set Certbot image
if [ -z ${CERTBOT_IMAGE+x} ]; then CERTBOT_IMAGE='certbot/certbot'; fi

# Set key size
if [ -z ${RSA_KEY_SIZE+x} ]; then RSA_KEY_SIZE=4096; fi

# Check Diffie-Hellman parameter
if [ ! -f "${PWD}"/certbot/conf/dhparams/dhparam.pem ]; then
    echo "### Creating Diffie-Hellman parameter ..."
    docker-compose run --rm --entrypoint \
        "mkdir -p /etc/letsencrypt/dhparams" prd-certbot-app
    docker-compose run --rm --entrypoint \
        "openssl dhparam -out /etc/letsencrypt/dhparams/dhparam.pem $RSA_KEY_SIZE" prd-certbot-app
fi

# Create dummy certificates if there is no renewal file from certbot.
for file in $CONFIG_DIR; do
    domain=$(basename "$file" | sed -e 's/public_\(.*\).conf/\1/')
    if [ ! -f ./certbot/conf/renewal/"$domain".conf ]; then
        echo "### Creating dummy certificate for $domain ... "
        docker-compose run --rm --entrypoint \
            "mkdir -p /etc/letsencrypt/live/$domain/" prd-certbot-app
        docker-compose run --rm --entrypoint \
            "openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1 \
            -keyout '/etc/letsencrypt/live/$domain/privkey.pem' \
            -out '/etc/letsencrypt/live/$domain/fullchain.pem' \
            -subj '/CN=localhost'" \
            prd-certbot-app
    fi
done

# Start NGINX webserver
docker-compose up --force-recreate -d prd-nginx-app

# Deleting dummy files
for file in $CONFIG_DIR; do
    domain=$(basename "$file" | sed -e 's/public_\(.*\).conf/\1/')
    if [ ! -f ./certbot/conf/renewal/"$domain".conf ]; then
        echo "### Deleting dummy certificate for $domain ..."
        docker-compose run --rm --entrypoint \
            "rm -rf /etc/letsencrypt/live/$domain" prd-certbot-app
    fi
done

# Enable staging mode if needed
if [ "$DRY_RUN" != 0 ]; then dry_run_arg="--dry-run"; fi

# Issue certificates
for file in $CONFIG_DIR; do
    domain=$(basename "$file" | sed -e 's/public_\(.*\).conf/\1/')
    echo "### Creating certificate for $domain ... "
    docker-compose run --rm --entrypoint "\
    certbot certonly \
    $dry_run_arg \
    --webroot \
    --webroot-path=/var/www/certbot/ \
    --email $EMAIL_ADDRESS \
    --agree-tos \
    --no-eff-email \
    --rsa-key-size $RSA_KEY_SIZE \
    --keep-until-expiring \
    --domains $domain" prd-certbot-app
done

# while [ "docker inspect -f {{.State.Running}} prd-nginx-app" != "true" ]; do
#     sleep 2
# done

# Reload nginx if config syntax is ok
echo "### Reloading nginx ..."
docker exec -it prd-nginx-app bash -c "nginx -t && nginx -s reload"
