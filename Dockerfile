FROM alpine:3.4

RUN apk --no-cache add bash grep curl libxml2-utils jq ffmpeg rtmpdump git


COPY .crontab /var/spool/cron/crontabs/root

CMD crond -f
