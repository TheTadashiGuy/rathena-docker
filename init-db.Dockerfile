
FROM alpine:3.24

ARG RATHENA_REF=d4b8e7b8f16061cc2496d377ac8f777ce72a4f39

RUN apk add --no-cache git mariadb-client bash \
    && mkdir -p /rathena/sql-files \
    && git init /tmp/rathena \
    && cd /tmp/rathena \
    && git remote add origin https://github.com/rathena/rathena.git \
    && git fetch --depth 1 origin "${RATHENA_REF}" \
    && git checkout FETCH_HEAD \
    && cp -a sql-files/. /rathena/sql-files/ \
    && rm -rf /tmp/rathena

COPY init-db.sh /usr/local/bin/init-db.sh

RUN chmod +x /usr/local/bin/init-db.sh

ENTRYPOINT ["/usr/local/bin/init-db.sh"]
