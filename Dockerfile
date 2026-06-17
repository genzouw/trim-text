FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

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
