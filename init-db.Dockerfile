
FROM alpine:3.24

RUN apk add --no-cache mariadb-client bash

COPY init-db.sh /usr/local/bin/init-db.sh

RUN chmod +x /usr/local/bin/init-db.sh

ENTRYPOINT ["/usr/local/bin/init-db.sh"]
