FROM php:7.1

# 修改为国内源
RUN rm /etc/apt/sources.list && \
    echo "deb http://mirrors.163.com/debian/ jessie main non-free contrib \ndeb http://mirrors.163.com/debian/ jessie-updates main non-free contrib \ndeb http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib" > /etc/apt/sources.list

RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libcurl4-gnutls-dev \
    libmemcached-dev \
    zlib1g-dev \
    libxml2-dev \
    libtidy-dev \
    libssl-dev \
    libzookeeper-mt-dev \
    libmagickwand-dev \
    imagemagick \
    cmake \
    librabbitmq-dev \
    curl \
    wget \
    git \
    zip \
    libz-dev \
    libnghttp2-dev \
    libpcre3 \
    libpcre3-dev \
    && apt-get clean \
    && apt-get autoremove

#composer
RUN curl -sS https://install.phpcomposer.com/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer self-update --clean-backups \
    && composer config -g repo.packagist composer https://packagist.phpcomposer.com

RUN wget https://github.com/redis/hiredis/archive/v0.13.3.tar.gz -O hiredis.tar.gz \
    && mkdir -p hiredis \
    && tar -xf hiredis.tar.gz -C hiredis --strip-components=1 \
    && rm hiredis.tar.gz \
    && ( \
        cd hiredis \
        && make -j$(nproc) \
        && make install \
        && ldconfig \
    ) \
    && rm -r hiredis

# PHP核心扩展
RUN docker-php-ext-install -j$(nproc) mcrypt bcmath gettext mysqli pdo_mysql soap sockets tidy zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# PECL扩展
RUN pecl install msgpack \
	&& pecl install yar \
	&& pecl install yac-2.0.2 \
	&& pecl install igbinary \
	&& pecl install redis \
	&& pecl install memcached \
	&& pecl install mongodb \
	&& pecl install amqp \
	&& pecl install zookeeper-0.3.2 \
	&& pecl install imagick \
	&& docker-php-ext-enable msgpack yar yac igbinary redis memcached mongodb amqp zookeeper imagick

# 其它扩展
# Qconf
RUN curl -fsSL 'https://github.com/Qihoo360/QConf/archive/1.2.1.tar.gz' -o qconf.tar.gz \
	&& mkdir -p qconf \
	&& tar -xf qconf.tar.gz -C qconf --strip-components=1 \
	&& rm qconf.tar.gz \
	&& cd qconf/ \
	&& mkdir build && cd build \
	&& cmake .. && make && make install \
	&& cd ../driver/php \
	&& phpize \
	&& ./configure --with-libqconf-dir=/usr/local/qconf/include --enable-static LDFLAGS=/usr/local/qconf/lib/libqconf.a \
	&& make && make install \
	&& cd ../../.. && rm -r qconf \
	&& docker-php-ext-enable qconf


# mss
RUN curl -fsSL 'https://github.com/microhuang/php-mss/archive/v1.3.tar.gz' -o mss.tar.gz \
	&& mkdir -p mss \
	&& tar -xf mss.tar.gz -C mss --strip-components=1 \
	&& rm mss.tar.gz \
	&& cd mss \
	&& phpize \
	&& ./configure \
	&& make && make install \
	&& cd ../ && rm -r mss \
	&& docker-php-ext-enable mss

RUN wget https://github.com/swoole/swoole-src/archive/v2.1.2.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-async-redis --enable-mysqlnd --enable-coroutine --enable-openssl \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole
