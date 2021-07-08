FROM docker.io/debian:buster-slim AS build

ARG PYENV_URL='https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer'
ARG PYTHON_VERSIONS='3.5.10 3.6.14 3.7.11 3.8.11 3.9.6'
ARG TOX_VERSION='3.23.1'

ENV PATH="$PATH:/root/.pyenv/bin:/root/.pyenv/shims"

RUN apt-get update && \
    apt-get install -y \
      make build-essential libssl-dev \
      zlib1g-dev libbz2-dev git libreadline-dev \
      libsqlite3-dev wget curl llvm libncursesw5-dev \
      xz-utils tk-dev libxml2-dev libxmlsec1-dev \
      libffi-dev liblzma-dev && \
    curl -sL "${PYENV_URL}" | bash && \
    pyenv update && \
    for PYTHON in ${PYTHON_VERSIONS}; do pyenv install "${PYTHON}"; done && \
    echo ${PYTHON_VERSIONS} | xargs pyenv global && \
    pip3.9 install "tox==${TOX_VERSION}" && \
    pyenv rehash && \
    find /root/.pyenv/versions \
      -type d '(' \
      -name '__pycache__' \
      -o -name 'test' \
      -o -name 'tests' ')' \
      -exec rm -rfv '{}' + && \
    find /root/.pyenv/versions \
      -type f '(' \
      -name '*.py[co]' \
      -o -name '*.exe' ')' \
      -exec rm -fv '{}' +

FROM docker.io/debian:buster-slim
LABEL maintainer='Alex Wicks <alex@awicks.io>'

ARG BUILD_DATE COMMIT_SHA

LABEL org.opencontainers.image.title='tox' \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.description='Docker image containing python 3.5 through 3.9 and tox' \
      org.opencontainers.image.documentation='https://github.com/aw1cks/docker-tox/blob/master/README.md' \
      org.opencontainers.image.version='1.0' \
      org.opencontainers.image.source='https://github.com/aw1cks/docker-tox' \
      org.opencontainers.image.revision="${COMMIT_SHA}"

ENV PATH="$PATH:/root/.pyenv/bin:/root/.pyenv/shims"

COPY --from=build /root/.pyenv /root/.pyenv
RUN apt-get update && \
    apt-get install -y \
      zlib1g bzip2 wget curl llvm libncursesw5 xz-utils \
      tk-dev libxml2 libxmlsec1 libffi6 lzma && \
    apt-get remove -y libllvm7 && \
    rm -rf /root/.cache/pip && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

CMD ["tox"]
