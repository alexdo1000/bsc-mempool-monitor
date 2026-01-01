#./geth --config ./config.toml --datadir mainnet-geth-pbss-20250310  --cache 8000 
./geth --config ./config.toml --datadir mainnet-geth-pbss-20250310 --cache 8000 --txpool.globalslots 50000 --txpool.globalqueue 25000 --txpool.accountslots 16 --txpool.accountqueue 16 --cache.preimages --http.api eth,net,web3,txpool,debug

