FROM quay.io/icgc-argo/dna-seq-processing-tools:base-docker.0.1.1

LABEL org.opencontainers.image.source https://github.com/icgc-argo/demo-wfpkgs

ENV PATH="/tools:${PATH}"

WORKDIR /tools

COPY *.py /tools/

CMD ["/bin/bash"]