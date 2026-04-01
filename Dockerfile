FROM golang:1.24-bookworm AS builder

WORKDIR /build
COPY src/ ./

RUN go mod tidy && \
    go build -o arozos -ldflags "-s -w" -trimpath

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /arozos

COPY --from=builder /build/arozos ./arozos
COPY src/web ./web/
COPY src/system ./system/

EXPOSE 8080

ENTRYPOINT ["./arozos"]
CMD ["-port", "8080"]
