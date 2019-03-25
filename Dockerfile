FROM alpine:3.4


COPY .crontab /var/spool/cron/crontabs/root

CMD crond -f
