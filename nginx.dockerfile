FROM nginx:latest

COPY nginx/conf/* /etc/nginx/conf.d/

HEALTHCHECK CMD service nginx status || exit 1