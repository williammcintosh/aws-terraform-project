FROM rust:buster as builder

WORKDIR /app
RUN USER=root cargo new --bin backend
COPY Cargo.toml Cargo.lock ./backend/

WORKDIR /app/backend
# Uses our pre-prepraed queries
ENV SQLX_OFFLINE=1
# Build dependencies only because we've not yet copied our own code
RUN cargo build

# Copies the executable over to the new, slimmer container
COPY ./ ./
ENV SQLX_OFFLINE=1
# Build our actual source code using the prior dependencies we've already built
RUN cargo build

# Build another small container
FROM debian:buster-slim
RUN apt update \
    && apt install -y openssl ca-certificates \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
WORKDIR /app

# COPY --from=builder /app/backend/target/debug/backend ./
# COPY ./templates ./templates
ENV SQLX_OFFLINE=1
# Run our backend
CMD ["/app/backend"]