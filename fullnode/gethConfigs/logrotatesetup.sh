sudo cp /home/ubuntu/bsc-mempool-monitor/fullnode/gethConfigs/erigon-logrotate /etc/logrotate.d/erigon
sudo chmod 644 /etc/logrotate.d/erigon
sudo logrotate -f /etc/logrotate.d/erigon