FROM ubuntu:18.04

ARG DUCKDB_VERSION=v1.2.0
ARG BUILD_ARCH=linux_amd64

RUN apt-get update && apt-get install -y \
  sudo \
  build-essential \
  g++ \
  curl \
  wget \
  gnupg \
  git \
  libssl-dev \
  openssh-client \
  unzip \
  ninja-build \
  software-properties-common \
  && apt-get clean

RUN curl --proto '=https' --tlsv1.2 -sSfL https://get.static-web-server.net | sh

RUN wget -qO- https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add - && \
  apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main' && \
  apt-get update && apt-get install -y cmake

WORKDIR /app
RUN mkdir -p extensions/${DUCKDB_VERSION}/${BUILD_ARCH}

# Clone the repository with recursive submodules and build it
RUN git clone --recursive https://github.com/definite-app/duckdb_gsheets.git

RUN cd duckdb_gsheets && \
  DUCKDB_GIT_VERSION=${DUCKDB_VERSION} make set_duckdb_version && \
  make GEN=ninja EXT_RELEASE_FLAGS=-DCMAKE_CXX_FLAGS=-fpermissive release

WORKDIR /app
RUN cp duckdb_gsheets/build/release/extension/gsheets/gsheets.duckdb_extension extensions/${DUCKDB_VERSION}/${BUILD_ARCH}/gsheets.duckdb_extension

RUN gzip -c extensions/${DUCKDB_VERSION}/${BUILD_ARCH}/gsheets.duckdb_extension > extensions/${DUCKDB_VERSION}/${BUILD_ARCH}/gsheets.duckdb_extension.gz

CMD ["static-web-server", "--port", "8080", "--root", "./extensions", "-x", "true", "--log-level", "debug"]
