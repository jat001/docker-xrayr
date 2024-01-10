FROM alpine

RUN apk add --no-cache bash curl && rm -rf /var/cache/apk/*

COPY --from=mikefarah/yq /usr/bin/yq /usr/bin/yq
COPY --from=ghcr.io/xrayr-project/xrayr /usr/local/bin/XrayR /usr/bin/xrayr

RUN adduser -h / -g '' -s /sbin/nologin -D -H xrayr
USER xrayr:xrayr

COPY --chown=xrayr:xrayr ./config /etc/xrayr
RUN mkdir /etc/xrayr/conf.d /etc/xrayr/node.d /tmp/xrayr
COPY ./docker-entrypoint.sh /

VOLUME ["/tmp/xrayr"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["xrayr", "-c", "/tmp/xrayr/config.yaml"]
