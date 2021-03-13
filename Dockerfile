FROM ghcr.io/miguelndecarvalho/docker-baseimage-archlinux:latest

LABEL maintainer="MiguelNdeCarvalho <geral@miguelndecarvalho.pt>"

RUN echo "- install packages needed -" && \
    pacman -Syu --noconfirm \
    base-devel \
    git \
	cronie

RUN echo "- add abc user to root list -" && \
    echo "abc ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN echo "- install aurutils and haste-client" && \
    runuser -l abc -c 'git clone --depth 1 https://aur.archlinux.org/aurutils.git /tmp/aurutils/' && \
    runuser -l abc -c 'cd /tmp/aurutils/ && makepkg --noconfirm -sci' && \
    curl -L "https://github.com/zneix/haste-client/releases/download/1.1/haste" -o /usr/bin/hastebin && \
    chmod +x /usr/bin/hastebin

RUN echo "- cleanup -" && \
    pacman -Scc --noconfirm && \
    rm -rf /tmp/*

COPY rootfs /
