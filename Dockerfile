FROM ghcr.io/miguelndecarvalho/docker-baseimage-archlinux:latest

LABEL maintainer="MiguelNdeCarvalho <geral@miguelndecarvalho.pt>"

RUN echo "- install packages needed -" && \
    pacman -Syu --noconfirm \
    git \
	cronie

RUN echo "- create user -" && \
    mkdir /home/abc && \
    useradd -d /home/abc abc && \
    chown abc /home/abc && \
    echo "abc ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN echo "- install aurutils and privatebin" && \
    runuser -l abc -c 'git clone --depth 1 https://aur.archlinux.org/aurutils.git /home/abc/aurutils/' && \
    runuser -l abc -c 'pacman-key --export DBE7D3DD8C81D58D0A13D0E76BC26A17B9B7018A | gpg --import' && \
    runuser -l abc -c 'cd /home/abc/aurutils/ && makepkg --noconfirm -sci && rm -rf /home/abc/aurutils/' && \
    mkdir /app && \
    curl -Lo /app/privatebin https://github.com/matthewpi/privatebin/releases/download/v0.0.1/privatebin && \
    chmod +x /app/privatebin

RUN echo "- cleanup -" && \
    pacman -Scc --noconfirm

COPY rootfs /
