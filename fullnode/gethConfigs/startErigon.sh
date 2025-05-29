#!/bin/bash

erigon \
  --config /home/ubuntu/bsc-mempool-monitor/fullnode/gethConfigs/mainnet/erigon-config.toml \
  --datadir /home/ubuntu/full/erigon \
  --chain bsc \
  --prune.mode minimal \
  --batchSize 2g \
  --db.size.limit 300G \
  --http \
  --http.addr 0.0.0.0 \
  --http.port 8545 \
  --http.api eth,net,web3,txpool,debug,trace \
  --http.corsdomain "*" \
  --http.vhosts "*" \
  --private.api.addr 0.0.0.0:9090 \
  --authrpc.port 8551 \
  --port 30303 \
  --log.console.verbosity 3 \
  --diagnostics.disabled \
  --metrics \
  --metrics.addr 0.0.0.0 \
  --metrics.port 6060 \
  --sync.loop.block.limit 10000 \
  --db.pagesize 64kb \
  --rpc.batch.concurrency 4 \
  --rpc.batch.limit 1000 \
  --db.read.concurrency 4 \
  --log.console.verbosity 4 \
  --log.dir.verbosity 4 \
  --log.dir.path ./logs \
  --log.dir.prefix erigon
#   --torrent.download.rate 20mb