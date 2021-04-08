FROM alpine:3.13

# Inspiration from https://github.com/gmr/alpine-pgbouncer/blob/master/Dockerfile
# Download dependencies
RUN apk --update add autoconf \
  autoconf-doc \
  automake \
  udns \
  udns-dev \
  gcc \
  git \
  libc-dev \
  libevent \
  libevent-dev \
  libtool \
  make \
  openssl-dev \
  pkgconfig \
  postgresql-client 

# Clone repository
RUN git clone https://github.com/NAlexPear/pgbouncer && \
  cd pgbouncer && \
  git submodule init && \
  git submodule update

WORKDIR ./pgbouncer

# Compile
RUN ./autogen.sh && \
  ./configure --prefix=/usr --with-udns && \
  make 

# Manual install
RUN cp pgbouncer /usr/bin && \
  mkdir -p /etc/pgbouncer /var/log/pgbouncer /var/run/pgbouncer && \
  # entrypoint installs the configuation, allow to write as postgres user
  cp etc/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini.example && \
  cp etc/userlist.txt /etc/pgbouncer/userlist.txt.example && \
  addgroup -g 70 -S postgres 2>/dev/null && \
  adduser -u 70 -S -D -H -h /var/lib/postgresql -g "Postgres user" -s /bin/sh -G postgres postgres 2>/dev/null && \
  chown -R postgres /var/run/pgbouncer /etc/pgbouncer

# Cleanup
RUN cd .. && \
  rm -rf ./pgbouncer*  && \
  apk del --purge autoconf autoconf-doc automake udns-dev curl gcc libc-dev libevent-dev libtool make libressl-dev pkgconfig

ADD entrypoint.sh /entrypoint.sh
USER postgres
EXPOSE 5432
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/pgbouncer", "/etc/pgbouncer/pgbouncer.ini"]
