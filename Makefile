SSH_KEY_DIR := .ssh
SSH_KEY     := $(SSH_KEY_DIR)/copilot-sandbox

# Instance number — set N to run multiple isolated sandboxes side by side.
#   make up N=1   -> port 2222
#   make up N=2   -> port 2223
#   make up N=3   -> port 2224 ...
N       ?= 1
PORT    := $(shell echo $$((2221 + $(N))))
PROJECT := copilot-sandbox-$(N)

# Injected into every docker compose invocation so each N gets its own
# project (isolated container/network/volumes) and its own host port.
COMPOSE := COMPOSE_PROJECT_NAME=$(PROJECT) SANDBOX_PORT=$(PORT) docker compose

.PHONY: build up down ssh ps clean help down-all prune

$(SSH_KEY):
	@mkdir -p $(SSH_KEY_DIR)
	@ssh-keygen -t ed25519 -f $(SSH_KEY) -N "" -q
	@echo "✓ SSH keypair generated at $(SSH_KEY)"

build: ## Build the container
	$(COMPOSE) build

up: $(SSH_KEY) ## Start a sandbox (set N for multiple, e.g. make up N=2)
	$(COMPOSE) up -d
	@echo "✓ Sandbox '$(PROJECT)' up — SSH with: make ssh N=$(N)  (port $(PORT))"

down: ## Stop and remove a sandbox (set N to target one, e.g. make down N=2)
	$(COMPOSE) down

down-all: ## Stop and remove ALL sandboxes (running or stopped)
	@projects=$$(docker ps -a --filter "name=copilot-sandbox-" \
	    --format '{{.Label "com.docker.compose.project"}}' | grep -v '^$$' | sort -u); \
	if [ -z "$$projects" ]; then \
	    echo "No sandboxes found."; \
	else \
	    for p in $$projects; do \
	        echo "→ Stopping $$p"; \
	        COMPOSE_PROJECT_NAME=$$p docker compose down; \
	    done; \
	fi

ssh: ## SSH into a sandbox (set N to target one, e.g. make ssh N=2)
	ssh -p $(PORT) -i $(SSH_KEY) -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dev@localhost

ps: ## List all running sandboxes
	@docker ps --filter "name=copilot-sandbox-" --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

clean: ## Remove a sandbox's container/image (set N), then remove SSH keys
	$(COMPOSE) down --rmi local
	rm -rf $(SSH_KEY_DIR)

prune: ## Reclaim Docker disk space (dangling images, stopped containers, build cache)
	docker system prune -f

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
