.PHONY: build clean run rebuild

build:
	@echo "Building plugin..."
	@mkdir -p modules
	@docker run --rm -w "/builder" -v "${PWD}:/builder" \
		heroiclabs/nakama-pluginbuilder:3.22.0 \
		build -buildmode=plugin -trimpath -o ./modules/backend.so
	@echo "✅ Build complete!"

clean:
	@echo "Cleaning up..."
	@docker-compose down
	@rm -rf modules/
	@echo "✅ Cleaned!"

run: build
	@echo "Starting Nakama..."
	@docker-compose up

rebuild: clean build

deps:
	@echo "Updating dependencies..."
	@go mod tidy
	@go mod vendor
	@echo "✅ Dependencies updated!"

dev: deps run
