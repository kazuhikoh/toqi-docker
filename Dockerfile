FROM alpine:3.4

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
    pip3 install -U git+https://github.com/kazuhikoh/scrapiyo.git

WORKDIR /usr/bin
COPY ./bin/config /usr/bin/config
RUN ln -s /opt/slacky/slacky.sh slacky

COPY .crontab /var/spool/cron/crontabs/root
COPY ./cron /usr/bin/cron

RUN chmod +x /usr/bin/cron/sorapiyo-notify.sh

CMD crond -f
