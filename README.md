# docker-kupo

Builds [Kupo](https://github.com/IntersectMBO/kupo) from source on Debian.
This image follows the same multi-stage pattern as our other Cardano Docker
images: build from the upstream tag with the Blink Haskell base image, then
copy the resulting executable into a slim runtime image.

The default build currently tracks Kupo `v2.11.0.1`, the latest IntersectMBO
release at the time this Dockerfile was created.

## Building

```bash
docker build -t ghcr.io/blinklabs-io/kupo .
```

To build a different upstream tag:

```bash
docker build \
  --build-arg KUPO_VERSION=2.11.0.1 \
  --build-arg KUPO_REF=tags/v2.11.0.1 \
  -t ghcr.io/blinklabs-io/kupo .
```

## Running

By default, the container connects directly to a Cardano node socket at
`/ipc/node.socket`, stores the SQLite database under `/data`, binds HTTP on
`0.0.0.0:1442`, and uses Cardano configuration files from
`/opt/cardano/config/$NETWORK/config.json`.

Kupo requires a starting point on the first run. Provide `KUPO_SINCE` or pass
`--since` directly.

```bash
docker run --detach \
  --name kupo \
  -e NETWORK=preprod \
  -e KUPO_SINCE=origin \
  -e KUPO_MATCH='addr_test1...' \
  -v kupo-data:/data \
  -v node-ipc:/ipc \
  -p 1442:1442 \
  ghcr.io/blinklabs-io/kupo
```

Multiple match patterns can be provided as a comma-separated `KUPO_MATCH`
value, or by passing repeated `--match` options after `run`.

```bash
docker run --rm \
  -v kupo-data:/data \
  -v node-ipc:/ipc \
  -p 1442:1442 \
  ghcr.io/blinklabs-io/kupo run \
    --since origin \
    --match 'addr_test1...' \
    --match 'addr_test1...'
```

### Ogmios

To connect through Ogmios instead of a local node socket:

```bash
docker run --detach \
  --name kupo \
  -e KUPO_CHAIN_PRODUCER=ogmios \
  -e KUPO_OGMIOS_HOST=127.0.0.1 \
  -e KUPO_OGMIOS_PORT=1337 \
  -e KUPO_SINCE=origin \
  -e KUPO_MATCH='addr_test1...' \
  -v kupo-data:/data \
  -p 1442:1442 \
  ghcr.io/blinklabs-io/kupo
```

### Configuration

The entrypoint maps common environment variables to Kupo CLI options:

- `NETWORK`, `CARDANO_NETWORK`, or `KUPO_NETWORK`: network config directory
  under `/opt/cardano/config` when using a node socket.
- `KUPO_CHAIN_PRODUCER`: `node` (default), `ogmios`, `hydra`, or `read-only`.
- `KUPO_NODE_SOCKET`: Cardano node socket path. Defaults to `/ipc/node.socket`.
- `KUPO_NODE_CONFIG`: Cardano node config path. Defaults to
  `/opt/cardano/config/$KUPO_NETWORK/config.json`.
- `KUPO_OGMIOS_HOST`: Ogmios IPv4 address when `KUPO_CHAIN_PRODUCER=ogmios`.
- `KUPO_OGMIOS_PORT`: Ogmios port when `KUPO_CHAIN_PRODUCER=ogmios`.
- `KUPO_HYDRA_HOST`: Hydra IPv4 address when `KUPO_CHAIN_PRODUCER=hydra`.
  Required; no default.
- `KUPO_HYDRA_PORT`: Hydra port when `KUPO_CHAIN_PRODUCER=hydra`. Required;
  no default.
- `KUPO_WORKDIR`: SQLite database directory. Defaults to `/data`.
- `KUPO_IN_MEMORY=true`: use Kupo's in-memory database mode.
- `KUPO_HOST`: HTTP bind address. Defaults to `0.0.0.0`.
- `KUPO_PORT`: HTTP port. Defaults to `1442`.
- `KUPO_SINCE`: starting chain point, for example `origin`, `tip`, or
  `slot.hash`.
- `KUPO_MATCH`: comma-separated match patterns.
- `KUPO_PRUNE_UTXO=true`: pass `--prune-utxo`.
- `KUPO_DEFER_DB_INDEXES=true`: pass `--defer-db-indexes`.
- `KUPO_GC_INTERVAL`: pass `--gc-interval`.
- `KUPO_LOG_LEVEL`: pass `--log-level`.

Any Kupo option can also be passed directly:

```bash
docker run --rm ghcr.io/blinklabs-io/kupo --help
docker run --rm ghcr.io/blinklabs-io/kupo health-check --host 127.0.0.1
```
