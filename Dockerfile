FROM archlinux/base

LABEL maintainer="MiguelNdeCarvalho <geral@miguelndecarvalho.pt>"

COPY rootfs .

RUN ./setup.sh && \
    rm ./setup.sh

CMD ["./start.sh"]
