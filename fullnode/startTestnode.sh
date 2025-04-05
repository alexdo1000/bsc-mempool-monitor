geth --config /home/ubuntu/bsc-mempool-monitor/fullnode/testnet/config.toml \
  --datadir /home/ubuntu/snapshots/testnet \
  --cache 8000 \
  --cache.preimages \
  --snapshot=false \
  --syncmode snap \
  --state.scheme path \
  --maxpeers 200