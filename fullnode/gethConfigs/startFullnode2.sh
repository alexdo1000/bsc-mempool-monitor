geth --config /home/ubuntu/bsc-mempool-monitor/fullnode/gethConfigs/mainnet/config.toml \
  --datadir /home/ubuntu/full/geth \
  --cache 24000 \
  --cache.preimages \
  --syncmode snap \
  --state.scheme path \
  --ws \
  --ws.addr 0.0.0.0 \
  --ws.port 8576 \
  --ws.api eth,net,web3,txpool \
  --history.transactions=90000 \
  --db.engine=pebble \
  --tries-verify-mode=local \
  --snapshot=true
  # --snapshot=false \
