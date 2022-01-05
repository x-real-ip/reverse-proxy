# reverse-proxy

[![Build Status](https://drone.theautomation.nl/api/badges/theautomation/reverse-proxy/status.svg)](https://drone.theautomation.nl/theautomation/reverse-proxy)
![GitHub repo size](https://img.shields.io/github/repo-size/theautomation/reverse-proxy?logo=Github)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/theautomation/reverse-proxy?logo=github)
![GitHub last commit (branch)](https://img.shields.io/github/last-commit/theautomation/reverse-proxy/main?logo=github)

[Nginx](https://www.nginx.com/): using this a reverse proxy which takes the client request, passes it on to one or more servers, and subsequently delivers the server's response back to the clients.

[Certbot](https://www.nginx.com/): a free, open source software tool for automatically using Let’s Encrypt certificates on manually-administrated websites and services to enable HTTPS.

## first run

1. Remove all non-default configuration files from "nginx/conf" so that nginx does not load the configuration files at boot time. Because paths to the certificates are defined in the conf files that don't exist yet, nginx first boot will fail and therefore certbot can't retrieving certificates over port 80 since the nginx container is not running.
2. Bring up nginx and certbot for the first time with docker-compose command.

```bash
docker-compose up -d
```

3. Once both containers have started, place the conf files that contain a certificate reference in the "nginx/conf" folder
4. Fill in the variables in "cert.sh file
5. Run the bash script cert.sh, it will create a Diffie-Hellman parameter file if it doesn't exist it will fetch certificates based on the configuration file names. Each configuration file with prefix "public" gets its own certificate.
