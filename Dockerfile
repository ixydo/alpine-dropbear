FROM alpine:latest

ADD rootfs /

RUN apk --no-cache add dropbear sudo \
 && adduser -s /bin/sh -D dbear \
 && chown -R dbear:dbear /home/dbear

CMD ["/usr/sbin/dropbear", "-RFEwg", "-p", "22"]
