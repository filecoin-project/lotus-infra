FROM golang:1.13.3-stretch AS builder
MAINTAINER Lotus Development Team

RUN apt-get update && apt-get install -y ca-certificates build-essential clang jq

COPY ./lotus /go/lotus

WORKDIR /go/lotus

RUN make
RUN make stats

FROM ubuntu:18.04 AS base
MAINTAINER Lotus Development Team

# Base resources
COPY --from=builder /etc/ssl/certs                       /etc/ssl/certs
COPY --from=builder /lib/x86_64-linux-gnu/libdl-2.24.so  /lib/x86_64-linux-gnu/libdl-2.24.so
COPY --from=builder /lib/x86_64-linux-gnu/librt.so.1     /lib/x86_64-linux-gnu/librt.so.1
COPY --from=builder /lib/x86_64-linux-gnu/libgcc_s.so.1  /lib/x86_64-linux-gnu/libgcc_s.so.1
COPY --from=builder /lib/x86_64-linux-gnu/libutil.so.1   /lib/x86_64-linux-gnu/libutil.so.1

COPY --from=builder /go/lotus/lotus                      /usr/local/bin/lotus
COPY --from=builder /go/lotus/stats                      /usr/local/bin/stats
