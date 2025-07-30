read -p "Enter snapshot url: " SNAPSHOT_URL

# Using 48Club snapshots for the first time
# Install dependencies, using Debian 12 as an example
sudo apt install -yfqq aria2 zstd pv openssl tar
# Download the snapshot
aria2c -s4 -x4 -k1024M -o snapshot.tar.zst https://complete.snapshots.48.club/geth.full.50241312.tar.zst

pv snapshot.tar.zst | openssl md5
# Extract the snapshot
pv snapshot.tar.zst | tar --use-compress-program="zstd -d" -xf snapshot.tar.zst
