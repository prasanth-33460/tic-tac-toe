# Stage 1: Build the Go plugin using the official Nakama pluginbuilder.
# The plugin MUST be compiled with the exact same Go toolchain as the
# Nakama binary, which is why we use this specific builder image.
FROM heroiclabs/nakama-pluginbuilder:3.22.0 AS builder

WORKDIR /backend
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -buildmode=plugin -trimpath -o ./modules/backend.so

# Stage 2: Production Nakama image with the compiled plugin.
FROM registry.heroiclabs.com/heroiclabs/nakama:3.22.0

COPY --from=builder /backend/modules/backend.so /nakama/data/modules/backend.so

ENTRYPOINT ["/bin/sh", "-ecx"]
CMD ["/nakama/nakama migrate up --database.address $DATABASE_URL && exec /nakama/nakama --name nakama1 --database.address $DATABASE_URL --logger.level INFO --session.token_expiry_sec 7200"]
