FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

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
