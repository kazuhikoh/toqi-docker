FROM alpine:3.4

RUN apk --no-cache add bash grep curl libxml2-utils jq ffmpeg rtmpdump git

WORKDIR /opt
RUN git clone https://github.com/kazuhikoh/slacky.git && \
    chmod +x slacky/slacky.sh

WORKDIR /usr/bin
RUN ln -s /opt/slacky/slacky.sh slacky

COPY .crontab /var/spool/cron/crontabs/root

CMD crond -f
