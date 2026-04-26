SSH_KEY_DIR := .ssh
SSH_KEY     := $(SSH_KEY_DIR)/copilot-sandbox

.PHONY: build up down ssh clean help

$(SSH_KEY):
	@mkdir -p $(SSH_KEY_DIR)
	@ssh-keygen -t ed25519 -f $(SSH_KEY) -N "" -q
	@echo "✓ SSH keypair generated at $(SSH_KEY)"

build: ## Build the container
	docker compose build

up: $(SSH_KEY) ## Build and start the container
	docker compose up -d --build

down: ## Stop and remove the container
	docker compose down

ssh: ## SSH into the container
	ssh -p 2222 -i $(SSH_KEY) -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dev@localhost

clean: ## Remove container, image, and SSH keys
	docker compose down --rmi local
	rm -rf $(SSH_KEY_DIR)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
