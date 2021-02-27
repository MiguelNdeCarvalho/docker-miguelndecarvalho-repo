FROM ghcr.io/miguelndecarvalho/docker-baseimage-archlinux:latest

LABEL maintainer="MiguelNdeCarvalho <geral@miguelndecarvalho.pt>"

RUN echo "- install packages needed -" && \
    pacman -Syu --noconfirm \
    git \
	cronie

RUN echo "- add abc user to root list -" && \
    echo "abc ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN echo "- install aurutils" && \
    s6-setuidgid abc git clone --depth 1 https://aur.archlinux.org/aurutils.git /tmp/aurutils/ && \
    s6-setuidgid abc cd /tmp/aurutils makepkg --noconfirm -sci

RUN echo "- cleanup -" && \
    pacman -Scc --noconfirm

COPY rootfs /
