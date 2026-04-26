# copilot-sandbox
Ephemeral Docker container for testing GitHub Copilot CLI in a clean environment.

## Why

`docker exec -it` creates a layered pseudo-TTY that breaks interactive prompts in Copilot CLI (e.g. `/plugin marketplace add` freezes the container). This setup uses SSH instead, which allocates a proper PTY and makes everything work as expected.

## What's included

- **Ubuntu 24.04** (pinned)
- git, curl, ripgrep, fd
- GitHub CLI (`gh`)
- Neovim + LazyVim (arm64/amd64 auto-detected)
- GitHub Copilot CLI
- SSH server (key-based auth only, no password, non-root `dev` user)

## Quick start

```bash
make up    # Build and start the container
make ssh   # SSH in

# Inside the container — authenticate and go
echo "ghp_your_token" | gh auth login --with-token
gh auth setup-git   # critical: sets gh as git credential helper for private repos
gh auth status      # verify auth

# Launch Copilot CLI
copilot
```

## Commands

```
make build   Build the container
make up      Build and start the container
make down    Stop and remove the container
make ssh     SSH into the container
make clean   Remove container, image, and SSH keys
make help    Show all commands
```

## Tear down

```bash
make down
```

Every restart is a fresh environment — nothing persists.

## SSH key

A project-local SSH keypair is generated automatically on first `make up` (stored in `.ssh/`, gitignored). No setup needed — it just works.

To regenerate the key:

```bash
make clean   # removes keys and container
make up      # generates a fresh key and starts the container
```

## Private marketplace repos

If you use `/plugin marketplace add` with private repos, `gh auth setup-git` is **required**. Without it, git has no credential helper and will prompt for a username/password — which freezes the terminal.

Verify it's set:

```bash
git config --global --list | grep cred
# Should show: credential.https://github.com.helper=!/usr/bin/gh auth git-credential
```

Your fine-grained PAT also needs access to the private repos you're adding as marketplaces.

## Notes

- SSH is bound to `127.0.0.1:2222` only (not exposed to network)
- The `dev` user has passwordless sudo
- Container runs with `init: true` for proper signal handling
