FROM php:7.0-fpm

RUN apt-get update && apt-get install -y --fix-missing \
        git \
        imagemagick \
        libmagickwand-dev \
        libmagickcore-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-install iconv \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install mcrypt \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install zip

RUN mkdir -p /src && git clone --depth 1 https://github.com/mkoppanen/imagick.git /src/imagick \
  && cd /src/imagick && phpize && ./configure --with-imagick=/usr/local/bin/convert && make && make install

# TODO change src file to php.ini-production for staging/production
RUN cp /usr/src/php/php.ini-development /usr/local/etc/php/php.ini

RUN cp /usr/local/etc/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf

RUN mkdir /var/run/php7-fpm

RUN echo "extension=imagick.so" > /usr/local/etc/php/conf.d/docker-php-ext-imagick.ini

# tweak php-fpm config
RUN sed -i -e "s/variables_order\s*=\s*\"GPCS\"/variables_order = \"EGPCS\"/g" /usr/local/etc/php/php.ini && \
sed -i -e "s/;date.timezone\s*=/date.timezone = 'America\/Los_Angeles'/" /usr/local/etc/php/php.ini && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 200M/g" /usr/local/etc/php/php.ini && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 200M/g" /usr/local/etc/php/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /usr/local/etc/php-fpm.conf && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /usr/local/etc/php-fpm.d/www.conf

RUN usermod -u 1000 www-data
RUN usermod -G staff www-data

CMD ["php-fpm"]

