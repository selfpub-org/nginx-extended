FROM alpine:3.7

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

RUN apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        libressl-dev \
        libffi-dev \
        zlib-dev \
        linux-headers \
        libxslt-dev \
        geoip-dev \
        perl-dev \
        libedit-dev \
        mercurial \
        bash \
        alpine-sdk \
        findutils \
      && export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

RUN wget nginx.org/download/nginx-1.16.1.tar.gz \
    && apk add pcre-dev libxml2 gd-dev \
    && tar -xvf nginx-1.16.1.tar.gz \
    && cd nginx-1.16.1 \
    && wget -c https://github.com/arut/nginx-dav-ext-module/archive/v3.0.0.tar.gz -O nginx-dav-ext-module.tar.gz \
    && tar -xzf nginx-dav-ext-module.tar.gz && rm nginx-dav-ext-module.tar.gz \
    && ./configure --sbin-path=/usr/sbin --conf-path=/etc/nginx/nginx.conf \
       --error-log-path=/var/log/nginx/error.log \
       --pid-path=/var/run/nginx.pid \
       --lock-path=/var/lock/nginx.lock \
       --http-log-path=/var/log/nginx/access.log \
       --http-client-body-temp-path=/var/lib/nginx/body \
       --http-proxy-temp-path=/var/lib/nginx/proxy \
       --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
       --with-http_stub_status_module \
       --with-http_ssl_module \
       --with-http_dav_module \
       --add-module=nginx-dav-ext-module-3.0.0 \
       --with-http_image_filter_module \
    && make && make install \
    && apk del .build-deps

RUN mkdir -p /var/lib/nginx \
    && mkdir -p /var/lib/nginx/body \
    && mkdir -p /var/lib/nginx/fastcgi \
    && mkdir -p /storage && chown nginx:nginx /storage

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
