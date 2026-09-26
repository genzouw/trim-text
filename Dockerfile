FROM alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

LABEL maintainer "genzouw <genzouw@gmail.com>"

RUN apk upgrade --no-cache \
  && apk add --no-cache \
    bash \
  ;

# 非 root ユーザーで実行することでコンテナエスケープのリスクを低減する (Trivy DS-0002)。
RUN addgroup -S trim && adduser -S -G trim trim

WORKDIR /app
COPY --chown=root:root --chmod=0555 ./tt /app/tt
USER trim:trim
ENTRYPOINT ["/app/tt"]
