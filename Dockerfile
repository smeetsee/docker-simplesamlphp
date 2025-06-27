FROM alpine AS builder
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
RUN apk add --no-cache jq
# TODO: download https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SSP_VERSION}/simplesamlphp-${SSP_VERSION}-full.tar.gz in job
ADD simplesamlphp-${SSP_VERSION}-full.tar.gz /var/www/html
WORKDIR /var/www/html
RUN jq '.repositories += {"repo-name": {"type":"vcs","url":"https://github.com/smeetsee/simplesamlphp-module-openidprovider"}}' composer.json > composer.tmp.json && \
    mv composer.tmp.json composer.json
RUN composer require 'cirrusidentity/simplesamlphp-module-authoauth2:^4.1' 'simplesamlphp/simplesamlphp-module-openidprovider:dev-master'

FROM php:${PHP_VERSION}-fpm-alpine AS php
RUN apk add --no-cache icu-dev
RUN docker-php-ext-install intl
COPY --from=builder /var/www/html /var/www/html
EXPOSE 9000

FROM nginx:alpine AS nginx
COPY nginx.conf.template /nginx.conf.template
COPY --from=builder /var/www/html /var/www/html
CMD ["/bin/sh" , "-c" , "envsubst < /nginx.conf.template > /etc/nginx/nginx.conf && exec nginx -g 'daemon off;'"]
EXPOSE 8080