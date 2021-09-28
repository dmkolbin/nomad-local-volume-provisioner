FROM ruby:2.6.6-buster

ENV DOCKER_PATH="docker/nomad-local-volume-provisioner" \
    WORKPATH="/opt/nomad-local-volume-provisioner" \
    BUNDLER_VERSION="2.1.4" \
    GEM_VERSION="3.1.4"

COPY ./ ${WORKPATH}/
COPY ${DOCKER_PATH}/root_dir /

RUN /basebuild/prepare.sh && \
    /basebuild/utilities.sh && \
    /basebuild/gems.sh && \
    /basebuild/cleanup.sh

WORKDIR ${WORKPATH}

CMD ["/usr/bin/nomad-local-volume-provisioner"]
