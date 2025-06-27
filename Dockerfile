ARG PHP_VERSION
FROM php:${PHP_VERSION}-cli-alpine AS builder
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
RUN apk add --no-cache jq icu-dev
RUN docker-php-ext-install intl ldap gmp
ADD simplesamlphp-version-full.tar.gz /var/www
WORKDIR /var/www
RUN rm -rf html && mv simplesamlphp-* html
WORKDIR /var/www/html
RUN jq '.repositories += {"repo-name": {"type":"vcs","url":"https://github.com/smeetsee/simplesamlphp-module-openidprovider"}}' composer.json > composer.tmp.json && \
    mv composer.tmp.json composer.json
RUN composer require 'cirrusidentity/simplesamlphp-module-authoauth2:^4.1' 'simplesamlphp/simplesamlphp-module-openidprovider:dev-master'

FROM php:${PHP_VERSION}-fpm-alpine AS php
RUN apk add --no-cache icu-dev
RUN docker-php-ext-install intl ldap gmp
COPY --from=builder /var/www/html /var/www/html
EXPOSE 9000

FROM nginx:alpine AS nginx
COPY nginx.conf.template /nginx.conf.template
COPY --from=builder /var/www/html /var/www/html
CMD ["/bin/sh" , "-c" , "envsubst < /nginx.conf.template > /etc/nginx/nginx.conf && exec nginx -g 'daemon off;'"]
EXPOSE 8080