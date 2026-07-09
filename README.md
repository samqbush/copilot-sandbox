# copilot-sandbox
Ephemeral Docker container for demoing and testing GitHub Copilot CLI over SSH.

## Why

Spin up a clean, disposable environment that simulates a real SSH workflow — perfect for quick demos and testing. The container provides a proper PTY over SSH (unlike `docker exec -it`, which breaks interactive prompts), resets to a blank slate on every restart, and takes seconds to launch.

## What's included

- **Ubuntu 24.04** (pinned)
- git, curl, ripgrep, fd
- GitHub CLI (`gh`)
- Neovim + LazyVim (arm64/amd64 auto-detected)
- GitHub Copilot CLI
- gnome-keyring (encrypted credential storage — no plain text tokens)
- SSH server (key-based auth only, no password, non-root `dev` user)

## Quick start

```bash
make up    # Build and start the container
make ssh   # SSH in

# Inside the container — authenticate GitHub CLI
gh auth login          # interactive OAuth device flow
gh auth setup-git      # sets gh as git credential helper for private repos
gh auth status         # verify auth

# Launch Copilot CLI (uses its own OAuth device flow for multi-org support)
copilot
```

> **Note:** Credentials are stored in `gnome-keyring` (encrypted, in-memory).
> No plain text config files. Everything is destroyed when the container stops.

## Commands

```
make build   Build the container
make up      Build and start a sandbox
make down    Stop and remove a sandbox
make down-all Stop and remove ALL running sandboxes
make ssh     SSH into a sandbox
make ps      List all running sandboxes
make clean   Remove container, image, and SSH keys
make help    Show all commands
```

## Running multiple sandboxes

Each sandbox is identified by an instance number `N` (default `1`). Pass `N` to
any command to spin up and manage isolated sandboxes side by side — each gets its
own Compose project, container, network, and host port (`2221 + N`):

```bash
make up  N=1    # sandbox 1 on port 2222
make up  N=2    # sandbox 2 on port 2223
make up  N=3    # sandbox 3 on port 2224

make ssh  N=2   # SSH into sandbox 2
make down N=2   # tear down just sandbox 2
make down-all   # tear down every sandbox at once
make ps         # list every running sandbox
```

Omitting `N` targets sandbox 1, so the classic `make up` / `make ssh` still work.
The auto-generated SSH keypair is shared across all instances.

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

- SSH is bound to `127.0.0.1:2222` only (not exposed to network); additional sandboxes use `2223`, `2224`, … (`2221 + N`)
- The `dev` user has passwordless sudo
- Container runs with `init: true` for proper signal handling
- `gh` tokens are stored in gnome-keyring (encrypted, in-memory) — not in plain text
- Copilot CLI uses OAuth device flow and supports authenticating to multiple orgs
