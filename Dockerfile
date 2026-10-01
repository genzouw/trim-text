FROM alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

LABEL maintainer "genzouw <genzouw@gmail.com>"

RUN apk upgrade --no-cache \
  && apk add --no-cache \
    bash \
  ;

# 非 root ユーザーで実行することでコンテナエスケープのリスクを低減する (Trivy DS-0002)。
# UID / GID を固定し、USER も数値で指定する。名前指定だとホスト側で解決できず、
# Kubernetes の runAsNonRoot が非 root を検証できないため (hadolint DL3066)。
RUN addgroup -S -g 10001 trim && adduser -S -u 10001 -G trim trim

WORKDIR /app
COPY --chown=root:root --chmod=0555 ./tt /app/tt
USER 10001:10001
ENTRYPOINT ["/app/tt"]
