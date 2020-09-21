FROM archlinux:20200908

LABEL maintainer="MiguelNdeCarvalho <geral@miguelndecarvalho.pt>"

RUN pacman -Syu --noconfirm --needed \
	base-devel \
	git \
	devtools \
	cronie && \
    mkdir /home/abc && \
    useradd -d /home/abc abc && \
    chown abc /home/abc && \
    echo "abc ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    runuser -l abc -c 'git clone --depth 1 https://aur.archlinux.org/aurutils.git /home/abc/aurutils/' && \
    runuser -l abc -c 'pacman-key --export DBE7D3DD8C81D58D0A13D0E76BC26A17B9B7018A | gpg --import' && \
    runuser -l abc -c 'cd /home/abc/aurutils/ && makepkg --noconfirm -sci && rm -rf /home/abc/aurutils/' && \
    pacman -Sc && \
    mkdir /app

COPY rootfs /app

CMD ["./app/start.sh"]