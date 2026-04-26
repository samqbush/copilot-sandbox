FROM ubuntu:24.04

ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

# Core tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates openssh-server \
    ripgrep fd-find sudo locales \
    && rm -rf /var/lib/apt/lists/*

# Fix locale (prevents weird terminal issues)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# fd-find installs as fdfind on Ubuntu
RUN ln -s $(which fdfind) /usr/local/bin/fd

# GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Neovim (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then NVIM_ARCH="arm64"; \
    else NVIM_ARCH="x86_64"; fi && \
    curl -sL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" \
    | tar xz -C /tmp && \
    mv /tmp/nvim-linux-${NVIM_ARCH} /opt/nvim && \
    ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim

# Copilot CLI
RUN curl -fsSL https://gh.io/copilot-install | bash

# SSH server setup (key-based auth only)
RUN mkdir -p /run/sshd && \
    sed -i 's/#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# Non-root dev user
RUN useradd -m -s /bin/bash -G sudo dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev

# LazyVim config (as dev user)
USER dev
RUN git clone https://github.com/LazyVim/starter ~/.config/nvim

# SSH authorized_keys directory
RUN mkdir -p ~/.ssh && chmod 700 ~/.ssh

USER root

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
