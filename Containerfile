FROM alpine:3.23

RUN apk add --no-cache \
  bash \
  ca-certificates \
  tini \
  vdirsyncer \
  py3-aiohttp-oauthlib \
  supercronic

# Setup directories and entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY vdirsyncer.sh /usr/local/bin/vdirsyncer.sh
RUN mkdir -p /app/.vdirsyncer /app/calendars && \
  chmod 0755 /usr/local/bin/entrypoint.sh /usr/local/bin/vdirsyncer.sh

WORKDIR /app

ENTRYPOINT [ "/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
