# WeChat Mini Program Development Makefile

.PHONY: install dev build lint type-check clean test help

# Default target
all: install build

# Install dependencies
install:
	@echo "Installing dependencies..."
	npm install

# Development mode with TypeScript watch
dev:
	@echo "Starting development mode..."
	npm run dev

# Build TypeScript
build:
	@echo "Building TypeScript..."
	npm run build

# Lint code
lint:
	@echo "Linting code..."
	npm run lint

# Type check
type-check:
	@echo "Running type check..."
	npm run type-check

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf miniprogram_npm/
	rm -rf node_modules/
	rm -f *.js
	rm -f pages/**/*.js

# Test (placeholder for future tests)
test:
	@echo "Running tests..."
	@echo "No tests configured yet"

# Help
help:
	@echo "Available commands:"
	@echo "  install     - Install dependencies"
	@echo "  dev         - Start development mode (TypeScript watch)"
	@echo "  build       - Build TypeScript"
	@echo "  lint        - Lint code"
	@echo "  type-check  - Run TypeScript type checking"
	@echo "  clean       - Clean build artifacts"
	@echo "  test        - Run tests (placeholder)"
	@echo "  help        - Show this help"
