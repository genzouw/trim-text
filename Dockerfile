FROM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11

LABEL maintainer "genzouw <genzouw@gmail.com>"

RUN apk upgrade --no-cache && \
  apk add --no-cache \
  bash \
  ;

# 非 root ユーザーで実行することでコンテナエスケープのリスクを低減する (Trivy DS-0002)。
RUN addgroup -S trim && adduser -S -G trim trim

WORKDIR /app
COPY --chown=root:root --chmod=0555 ./tt /app/tt
USER trim:trim
ENTRYPOINT ["/app/tt"]
