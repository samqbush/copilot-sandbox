SSH_KEY ?= ~/.ssh/id_ed25519.pub

.PHONY: build up down ssh clean

build: ## Build the container
	docker compose build

up: ## Build and start the container
	docker compose up -d --build

down: ## Stop and remove the container
	docker compose down

ssh: ## SSH into the container
	ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dev@localhost

clean: ## Remove container and image
	docker compose down --rmi local

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
