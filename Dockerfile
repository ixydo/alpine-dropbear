FROM alpine:latest

RUN apk --no-cache add dropbear sudo aws-cli curl jq bash \
 && adduser -s /bin/sh -D dbear \
 && chown -R dbear:dbear /home/dbear

ADD rootfs /

CMD ["/entrypoint.sh"]
