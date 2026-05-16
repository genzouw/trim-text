FROM alpine:3.23.4

LABEL maintainer "genzouw <genzouw@gmail.com>"

RUN apk add --no-cache \
  bash \
  ;

COPY ./tt /
ENTRYPOINT ["/tt"]
