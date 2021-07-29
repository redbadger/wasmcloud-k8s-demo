FROM wasmcloud/wasmcloud:0.18.2 as base

FROM alpine
RUN apk add --no-cache libc6-compat
COPY --from=base ./ /
COPY --from=base /etc/ssl/certs/ca-certificates.crt /etc/ssl/cert.pem

USER user:user
ENTRYPOINT ["/usr/local/bin/wasmcloud"]
