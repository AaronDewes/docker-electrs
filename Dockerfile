ARG VERSION=v0.8.9

FROM rust:1.44.1-slim-buster as builder

WORKDIR /build

RUN apt-get update \
    && apt-get install -y --no-install-recommends clang cmake git \
    libsnappy-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch $VERSION https://github.com/romanz/electrs .

RUN cargo install --locked --path .

# Create runtime image
FROM debian:buster-slim

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release .

RUN groupadd -r user \
    && adduser --disabled-login --system --shell /bin/false --uid 1000 --ingroup user user \
    && chown -R user:user /app

USER user

# Electrum RPC
EXPOSE 50001

# Prometheus monitoring
EXPOSE 4224

STOPSIGNAL SIGINT

HEALTHCHECK CMD curl -fSs http://localhost:4224/ || exit 1

ENTRYPOINT ["./electrs"]
