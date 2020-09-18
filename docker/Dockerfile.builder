FROM golang:1.14.7-stretch AS builder
MAINTAINER Lotus Development Team

RUN apt-get update && apt-get install -y ca-certificates build-essential clang ocl-icd-opencl-dev ocl-icd-libopencl1

ARG UID=1000
ARG GID=1000
ARG RUST_VERSION=nightly
ENV XDG_CACHE_HOME="/tmp"

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN addgroup -gid $GID filecoin && \
    adduser --no-create-home --disabled-password -uid $UID --ingroup filecoin --gecos "" filecoin && \
    mkdir -p "/go/pkg/mod" && \
    chown -R filecoin:filecoin "/go/pkg/mod"

RUN wget "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init"; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

COPY ./lotus /opt/filecoin

RUN chown -R filecoin:filecoin /opt/filecoin

USER filecoin
WORKDIR /opt/filecoin

ARG RUSTFLAGS=""
ARG GOFLAGS=""

RUN make deps lotus lotus-miner lotus-worker lotus-shed

FROM ubuntu:18.04 AS base
MAINTAINER Lotus Development Team

# Base resources
COPY --from=builder /etc/ssl/certs                           /etc/ssl/certs
COPY --from=builder /lib/x86_64-linux-gnu/libdl-2.24.so      /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/librt.so.1         /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libgcc_s.so.1      /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libutil.so.1       /lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/

COPY --from=builder /opt/filecoin/lotus                      /usr/local/bin/
COPY --from=builder /opt/filecoin/lotus-shed                 /usr/local/bin/
COPY --from=builder /opt/filecoin/lotus-miner                /usr/local/bin/
COPY --from=builder /opt/filecoin/lotus-worker               /usr/local/bin/
