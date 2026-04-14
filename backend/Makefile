.PHONY: build clean run rebuild deps dev logs stop

# Build the plugin inside Docker and start all services.
run:
	docker compose up --build

# Start services in background.
run-detached:
	docker compose up --build -d

# Stop running services.
stop:
	docker compose down

# Stop services and wipe all data (database, volumes).
clean:
	docker compose down -v

# Tail container logs.
logs:
	docker compose logs -f nakama

# Update Go dependencies.
deps:
	go mod tidy

# One-command: update deps then start.
dev: deps run
