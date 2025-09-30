# Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
sudo apt-get update && sudo apt-get install -y build-essential
sudo apt-get install aria2