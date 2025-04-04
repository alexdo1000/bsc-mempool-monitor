geth --config ./config.toml \
  --datadir mainnet-geth-pbss-20250310 \
  --cache 8000 \
  --cache.preimages \
  --snapshot=false \
  --syncmode snap \
  --state.scheme path \
  --maxpeers 50