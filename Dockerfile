FROM alpine:3.6

RUN apk update && apk upgrade &&  apk --update --no-cache add bash vsftpd augeas

COPY entry.sh /entry.sh

COPY vsftpd.aug /usr/share/augeas/lenses/dist/vsftpd.aug

RUN chmod +x /entry.sh

ENTRYPOINT ["/entry.sh"]

CMD ["/usr/sbin/vsftpd", "/etc/vsftpd/vsftpd.conf"]
