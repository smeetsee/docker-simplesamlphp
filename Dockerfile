ARG PHP_VERSION
FROM php:${PHP_VERSION}-cli-alpine AS builder
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
RUN apk add --no-cache jq icu-dev libldap openldap-dev samba-dev gmp-dev
RUN docker-php-ext-install intl ldap gmp
ADD simplesamlphp-version-full.tar.gz /var/www
WORKDIR /var/www
RUN rm -rf html && mv simplesamlphp-* html
WORKDIR /var/www/html
RUN jq '.repositories += {"repo-name": {"type":"vcs","url":"https://github.com/smeetsee/simplesamlphp-module-openidprovider"}}' composer.json > composer.tmp.json && \
    mv composer.tmp.json composer.json
RUN composer require 'cirrusidentity/simplesamlphp-module-authoauth2:^4.1' 'simplesamlphp/simplesamlphp-module-openidprovider:dev-master'

FROM php:${PHP_VERSION}-fpm-alpine AS phpfpm
RUN apk add --no-cache icu-dev libldap openldap-dev samba-dev gmp-dev
RUN docker-php-ext-install intl ldap gmp
COPY --from=builder /var/www/html /var/www/html
EXPOSE 9000

FROM nginx:alpine AS nginx
COPY nginx.conf.template /nginx.conf.template
COPY --from=builder /var/www/html /var/www/html
CMD ["/bin/sh" , "-c" , "envsubst '${SERVER_NAME}' < /nginx.conf.template > /etc/nginx/nginx.conf && exec nginx -g 'daemon off;'"]
EXPOSE 8080

FROM phpfpm AS php-adfsmfa
# In the file /var/www/html/modules/saml/src/IdP/SAML2.php, replace the block
#         if ($username !== null) {
#            $state['core:username'] = $username;
#         }
# with
#         if ($_REQUEST['Context'] !== null) {
#            $state['saml:RelayState'] = $_REQUEST['Context'];
#         }
RUN awk 'index($0, "if (\$username !== null) {") {print "if (\$_REQUEST[\"Context\"] !== null) {"; getline; print "    \$state[\"saml:RelayState\"] = \$_REQUEST[\"Context\"];"; next} {print}' /var/www/html/modules/saml/src/IdP/SAML2.php > /tmp/SAML2.php && mv /tmp/SAML2.php /var/www/html/modules/saml/src/IdP/SAML2.php
# In the files /var/www/html/vendor/simplesamlphp/saml2/src/Binding/HTTPPost.php,      and
#              /var/www/html/vendor/simplesamlphp/saml2-legacy/src/SAML2/HTTPPost.php, replace the block
#         if ($relayState !== null) {
#             $post['RelayState'] = $relayState;
#         }
# with
#         if ($relayState !== null) {
#             $post['Context'] = $relayState;
#         }
RUN awk 'index($0, "if (\$relayState !== null) {") {print; getline; print "    \$post[\"Context\"] = \$relayState;"; next} {print}' /var/www/html/vendor/simplesamlphp/saml2/src/Binding/HTTPPost.php > /tmp/HTTPPost.php && mv /tmp/HTTPPost.php /var/www/html/vendor/simplesamlphp/saml2/src/Binding/HTTPPost.php
RUN awk 'index($0, "if (\$relayState !== null) {") {print; getline; print "    \$post[\"Context\"] = \$relayState;"; next} {print}' /var/www/html/vendor/simplesamlphp/saml2-legacy/src/SAML2/HTTPPost.php > /tmp/HTTPPost.php && mv /tmp/HTTPPost.php /var/www/html/vendor/simplesamlphp/saml2-legacy/src/SAML2/HTTPPost.php