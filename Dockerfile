FROM alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

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
