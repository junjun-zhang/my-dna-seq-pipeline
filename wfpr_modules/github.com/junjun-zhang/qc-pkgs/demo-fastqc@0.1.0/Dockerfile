FROM pegi3s/fastqc:0.11.9

LABEL org.opencontainers.image.source https://github.com/junjun-zhang/qc-pkgs

ENV PATH="/tools:${PATH}"

COPY *.py /tools/

ENTRYPOINT ["/usr/bin/env"]

CMD ["/bin/bash"]
