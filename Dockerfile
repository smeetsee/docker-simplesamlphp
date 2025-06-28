ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm-alpine AS php
RUN apk add --no-cache icu-dev libldap openldap-dev samba-dev gmp-dev
RUN docker-php-ext-install intl ldap gmp
COPY moodle-src /var/www/html
EXPOSE 9000

FROM nginx:alpine AS nginx
COPY nginx.conf.template /nginx.conf.template
COPY moodle-src /var/www/html
CMD ["/bin/sh" , "-c" , "envsubst '${SERVER_NAME}' < /nginx.conf.template > /etc/nginx/nginx.conf && exec nginx -g 'daemon off;'"]
EXPOSE 8080