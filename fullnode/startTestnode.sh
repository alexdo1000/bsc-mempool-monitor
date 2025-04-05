# geth --config /home/ubuntu/bsc-mempool-monitor/fullnode/testnet/config.toml \
#   --datadir /home/ubuntu/snapshots/testnet/server/data-seed \
#   --cache 8000 \
#   --cache.preimages \
#   --snapshot=false \
#   --syncmode snap \
#   --state.scheme path \
#   --maxpeers 200

geth --config /home/ubuntu/bsc-mempool-monitor/fullnode/testnet/config.toml --datadir /home/ubuntu/snapshots/testnet/server/data-seed -cache 8000 --cache.preimages --snapshot=false --syncmode snap --state.scheme path --maxpeers 200 --ws --ws.addr 0.0.0.0 --ws.port 8576 --ws.api eth,net,web3,txpool