ARG NGINX_VERSION=1.31.0
FROM nginx:${NGINX_VERSION} as builder

# hadolint ignore=DL3008
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  wget \
  gcc \
  g++ \
  make \
  automake \
  libtool \
  libssl-dev \
  zlib1g-dev \
  libpcre2-dev && \
  rm -rf /var/lib/apt/lists/* && \
  wget --progress=dot:giga "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" && \
  tar -C "/usr/src" -xzvf "nginx-${NGINX_VERSION}.tar.gz"

WORKDIR /src/ngx_http_substitutions_filter_module
RUN git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git .

WORKDIR /usr/src/nginx-${NGINX_VERSION}

# Makes bash fail if anything befor a pipe (i.e. nginx -V) fails.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN NGINX_ARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') && \
  ./configure --with-compat --add-dynamic-module=/src/ngx_http_substitutions_filter_module "${NGINX_ARGS}" && \
  make modules


FROM nginx:${NGINX_VERSION}

# libbrotli1 upgraded to the Debian 13 security build (1.1.0-2+deb13u1) to fix CVE-2026-111497
# hadolint ignore=DL3008
RUN apt-get update && \
  apt-get install -y --no-install-recommends libbrotli1=* && \
  rm -rf /var/lib/apt/lists/*

COPY --chown=nginx:nginx nginx/nginx.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx nginx/nginx.static-blog.conf /etc/nginx/templates/default.conf.template
#COPY nginx/nginx.default.conf /etc/nginx/templates/default.conf.template
COPY --chown=nginx:nginx nginx-static /usr/share/nginx/html
COPY --from=builder /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_subs_filter_module.so /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_subs_filter_module.so /usr/lib/nginx/modules/

# ENV APP_HOST_NAME localhost
# ENV APP_PORT 8000
ENV SARWA_HOST www.sarwa.co

EXPOSE 8080

# Run as a non-root user (we listen on 8080 so no privileges needed).
# Ensure Nginx entrypoint can render templates and write its pid/log/cache.
RUN set -eux; \
  mkdir -p /var/cache/nginx /var/run /var/log/nginx /etc/nginx/conf.d; \
  chown -R nginx:nginx /var/cache/nginx /var/run /var/log/nginx /etc/nginx/conf.d /etc/nginx/templates /usr/share/nginx/html; \
  # /var/run is commonly a symlink to /run
  if [ -d /run ]; then chown -R nginx:nginx /run; fi

USER nginx
