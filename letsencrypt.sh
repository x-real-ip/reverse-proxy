#!/bin/bash
#
# Script written by Coen Stam
# This sets up Let's Encrypt SSL certificates and automatic renewal
# using certbot: https://certbot.eff.org
#
# Certificate files are placed into subdirectories under
# /etc/letsencrypt/live/*.
#
# A certificate will be created or renewed if it have a prefix "public_" in config filename.
#

set -e

# Absolute path to this script.
script=$(readlink -f "$0")
# Absolute path this script is in.
absolute_path=$(dirname "$script")

# change directory where this scripts lives
cd "${absolute_path}"

# Include ini
# shellcheck source=/dev/null
source ./letsencrypt.ini

now=$(date)

echo -e "\n--------------------------- ${now} --------------------------------------\n" >>log.log 2>&1
echo "Using the following config variables:" >>log.log 2>&1
cat ./letsencrypt.ini >>log.log 2>&1

# Check if docker-compose is installed
if ! [ -x "$(command -v docker-compose)" ]; then echo "### Error: docker-compose is not installed ..." exit 1 >>log.log 2>&1; fi

# Check if docker-compose file exists
if [ ! -f ./docker-compose.yml ]; then echo "### Error: docker-compose.yml not found ..." exit 1 >>log.log 2>&1; fi

# Set Certbot image
if [ -z ${CERTBOT_IMAGE+x} ]; then CERTBOT_IMAGE='certbot/certbot' >>log.log 2>&1; fi

# Set key size
if [ -z ${RSA_KEY_SIZE+x} ]; then RSA_KEY_SIZE=4096 >>log.log 2>&1; fi

# Check Diffie-Hellman parameter
if [ ! -f ./certbot/conf/dhparams/dhparam.pem ]; then
    echo "### Creating Diffie-Hellman parameter ..."
    docker-compose run --rm --entrypoint \
        "mkdir -p /etc/letsencrypt/dhparams" prd-certbot-app >>log.log 2>&1s
    docker-compose run --rm --entrypoint \
        "openssl dhparam -out /etc/letsencrypt/dhparams/dhparam.pem $RSA_KEY_SIZE" prd-certbot-app >>log.log 2>&1s
fi

# Create dummy certificates if there is no renewal file from certbot.
for file in $CONFIG_DIR; do
    domain=$(basename "$file" | sed -e 's/public_\(.*\).conf/\1/')
    if [ ! -f ./certbot/conf/renewal/"$domain".conf ]; then
        echo "### Creating dummy certificate for $domain ... " >>log.log 2>&1
        docker-compose run --rm --entrypoint \
            "mkdir -p /etc/letsencrypt/live/$domain/" prd-certbot-app
        docker-compose run --rm --entrypoint \
            "openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1 \
            -keyout '/etc/letsencrypt/live/$domain/privkey.pem' \
            -out '/etc/letsencrypt/live/$domain/fullchain.pem' \
            -subj '/CN=localhost'" \
            prd-certbot-app >>log.log 2>&1
    fi
done

# Start NGINX webserver
docker-compose up --force-recreate -d prd-nginx-app >>log.log 2>&1

until [ "docker inspect -f {{.State.Running}} prd-nginx-app" != "true" ]; do
    echo "### Waiting for nginx to start ..."
    sleep 2 >>log.log 2>&1
done

# Deleting dummy files
for file in $CONFIG_DIR; do
    domain=$(basename "$file" | sed -e 's/public_\(.*\).conf/\1/')
    if [ ! -f ./certbot/conf/renewal/"$domain".conf ]; then
        echo "### Deleting dummy certificate for $domain ..." >>log.log 2>&1
        docker-compose run --rm --entrypoint \
            "rm -rf /etc/letsencrypt/live/$domain" prd-certbot-app >>log.log 2>&1
    fi
done

# Enable staging mode if needed
if [ "$TEST" != 0 ]; then test_cert_arg="--test-cert" >>log.log 2>&1; fi

# Issue certificates
for file in $CONFIG_DIR; do
    domain=$(basename "$file" | sed -e 's/public_\(.*\).conf/\1/')
    echo "### Creating certificate for $domain ..." >>log.log 2>&1
    docker-compose run --rm --entrypoint "\
    certbot certonly \
    $test_cert_arg \
    --webroot \
    --webroot-path=/var/www/certbot/ \
    --email $EMAIL_ADDRESS \
    --agree-tos \
    --no-eff-email \
    --rsa-key-size $RSA_KEY_SIZE \
    --keep-until-expiring \
    --domains $domain" prd-certbot-app >>log.log 2>&1
done

# Restart nginx only if --test-cert was off
if [ "$TEST" == "0" ]; then
    until [ "docker inspect -f {{.State.Running}} prd-nginx-app" != "true" ]; do
        echo "### Waiting for nginx to start ..." >>log.log 2>&1
        sleep 2
    done
    echo "### Reloading nginx ..." >>log.log 2>&1
    docker exec prd-nginx-app bash -c "nginx -t && nginx -s reload" >>log.log 2>&1
fi
