FROM alpine:3.24

COPY render-conf.sh /usr/local/bin/render-conf.sh

RUN chmod +x /usr/local/bin/render-conf.sh

ENTRYPOINT ["/bin/sh", "/usr/local/bin/render-conf.sh"]
