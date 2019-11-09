FROM alpine:3.10.2

RUN apk --no-cache add \
    bash \
    grep \
    curl \
    git \
    python3 \
    python3-dev \
    jq

WORKDIR /opt
RUN git clone https://github.com/kazuhikoh/slacky.git && \
    chmod +x slacky/slacky.sh && \
    git clone https://github.com/kazuhikoh/xline.git && \
    chmod +x xline/xline.sh && \
    pip3 install -U git+https://github.com/kazuhikoh/scrapiyo.git

WORKDIR /usr/bin
COPY ./bin/config /usr/bin/config
RUN ln -s /opt/slacky/slacky.sh slacky && \
    ln -s /opt/xline/xline.sh xline

COPY .crontab /var/spool/cron/crontabs/root
COPY ./cron /usr/bin/cron

RUN chmod +x /usr/bin/cron/sorapiyo-notify.sh && \
    chmod +x /usr/bin/cron/linetl-notify.sh

CMD crond -f
