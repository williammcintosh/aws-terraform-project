FROM rust:buster as builder

WORKDIR /app
COPY ./ ./
RUN cargo build

FROM debian:buster-slim
WORKDIR /app
RUN apt update \
    && apt install -y openssl ca-certificates \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=builder /app/target/debug/rust_backend ./

CMD ["./rust_backend"]