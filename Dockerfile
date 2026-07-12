FROM ghcr.io/blinklabs-io/haskell:9.12.3-3.14.2.0-1 AS kupo-build

ARG KUPO_VERSION=2.11.0.1
ARG KUPO_REF=tags/v${KUPO_VERSION}
ARG CABAL_BUILD_FLAGS="-f production"

ENV KUPO_VERSION=${KUPO_VERSION}
ENV KUPO_REF=${KUPO_REF}

RUN apt-get update -y && \
  apt-get install -y --no-install-recommends \
    libsqlite3-dev && \
  rm -rf /var/lib/apt/lists/*

RUN echo "Building ${KUPO_REF}..." \
    && echo "${KUPO_REF}" > /KUPO_REF \
    && git clone https://github.com/IntersectMBO/kupo.git \
    && cd kupo \
    && git fetch --all --tags \
    && git checkout "${KUPO_REF}" \
    && cabal update \
    && cabal build kupo:exe:kupo ${CABAL_BUILD_FLAGS} \
    && mkdir -p /root/.local/bin/ \
    && cp -p "$(cabal list-bin kupo:exe:kupo ${CABAL_BUILD_FLAGS})" /root/.local/bin/ \
    && rm -rf /root/.cabal/packages \
    && rm -rf /usr/local/lib/ghc-${GHC_VERSION}/ /usr/local/share/doc/ghc-${GHC_VERSION}/ \
    && rm -rf /code/kupo/dist-newstyle/ \
    && rm -rf /root/.cabal/store/ghc-${GHC_VERSION}

FROM ghcr.io/blinklabs-io/cardano-configs:20260707-2 AS cardano-configs

FROM debian:bookworm-slim AS kupo
ENV LD_LIBRARY_PATH="/usr/local/lib"
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig"
COPY --from=kupo-build /usr/local/lib/ /usr/local/lib/
COPY --from=kupo-build /usr/local/include/ /usr/local/include/
COPY --from=kupo-build /root/.local/bin/kupo /usr/local/bin/
COPY --from=cardano-configs /config/ /opt/cardano/config/
COPY bin/ /usr/local/bin/
RUN apt-get update -y && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    libffi8 \
    libgmp10 \
    liblmdb0 \
    libncursesw5 \
    libnuma1 \
    libsnappy1v5 \
    libssl3 \
    libsystemd0 \
    libtinfo6 \
    liburing2 \
    llvm-14-runtime \
    netbase \
    pkg-config \
    sqlite3 \
    zlib1g && \
  rm -rf /var/lib/apt/lists/* && \
  groupadd --system appuser && \
  useradd --system --gid appuser --home-dir /nonexistent --no-create-home --shell /usr/sbin/nologin appuser && \
  mkdir -p /data /ipc && \
  chmod +x /usr/local/bin/* && \
  chown -R appuser:appuser /data /ipc /usr/local/bin

EXPOSE 1442
VOLUME ["/data", "/ipc"]
STOPSIGNAL SIGINT
HEALTHCHECK --interval=10s --timeout=5s --retries=3 CMD kupo health-check --host 127.0.0.1 --port "${KUPO_PORT:-1442}" || exit 1
USER appuser
ENTRYPOINT ["/usr/local/bin/entrypoint"]
