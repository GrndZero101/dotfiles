# Vanilla Ubuntu plus only what the packages need, so network scenarios are
# repeatable (--network none blocks apt). Build args pick the tmux version
# (22.04 = 3.2a) and drop or add packages, e.g. PKGS="zsh tmux stow git".
# ca-certificates is a "recommends" that --no-install-recommends drops, and
# git and curl can't use HTTPS without it.
ARG UBUNTU=24.04
FROM ubuntu:$UBUNTU
ARG PKGS="zsh tmux stow git curl"
RUN apt-get update && apt-get install -y --no-install-recommends $PKGS ca-certificates && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/zsh tester
USER tester
WORKDIR /home/tester
