geth --config ./config.toml \
  --datadir /home/ubuntu/snapshots/current \
  --cache 8000 \
  --cache.preimages \
  --snapshot=false \
  --syncmode snap \
  --state.scheme path \
  --maxpeers 50