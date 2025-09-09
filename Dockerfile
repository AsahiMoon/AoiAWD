# 前端
FROM node:14.17.0 as frontend
COPY . /aoi
WORKDIR /aoi/Frontend

RUN npm config set registry https://registry.npmmirror.com/ && \
    npm install 
RUN npm run build

# 后端
FROM php:7.2-cli
COPY --from=frontend /aoi /aoi
WORKDIR /aoi/AoiAWD
# 基本配置
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" && \
    echo "phar.readonly=Off" > "$PHP_INI_DIR/conf.d/phar.ini" && \
    cp -r /aoi/Frontend/dist/static/ /aoi/AoiAWD/src/public/ && \
    cp /aoi/Frontend/dist/index.html /aoi/AoiAWD/src/public/index.html
# 编译phar和影子文件（inotify-tools 从 github 搬运到码云）
RUN cd .. && cd TapeWorm && php compile.php &&\
    cd .. && cd Guardian && php compile.php &&\
    cd .. && cd RoundWorm &&\
    # sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list  && \
    # sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian-archive/debian buster main" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/debian-archive/debian-security buster/updates main" >> /etc/apt/sources.list &&\
    apt update && apt install -y wget &&\
    wget https://gitee.com/slug01sh/inotify-tools/attach_files/764348/download/inotify-tools-3.14.tar.gz && \
    tar zxf inotify-tools-3.14.tar.gz && cd inotify-tools-3.14/ && \
    ./configure && make && make install &&\
    cd .. && make

WORKDIR /aoi/AoiAWD
RUN pecl channel-update pecl.php.net && pecl install mongodb-1.9.2 && \ 
    docker-php-ext-enable mongodb && \
    php ./compile.php

ENTRYPOINT [ "sh", "/aoi/entrypoint.sh"]


