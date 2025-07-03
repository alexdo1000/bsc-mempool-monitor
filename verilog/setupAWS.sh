#!/bin/bash
set -e

echo "🚀 Setting up AWS F1 instance for FPGA mempool monitoring..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential development tools
echo "🔧 Installing development tools..."
sudo apt-get install -y \
    build-essential \
    git \
    wget \
    curl \
    unzip \
    python3 \
    python3-pip \
    cmake \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libusb-1.0-0-dev \
    udev \
    screen \
    htop \
    iotop \
    ethtool \
    tcpdump \
    wireshark \
    net-tools \
    bridge-utils

# Install Rust (for the CPU-side software)
echo "🦀 Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# Install AWS CLI v2
echo "☁️ Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Install AWS FPGA SDK
echo "🔧 Installing AWS FPGA SDK..."
cd ~
git clone https://github.com/aws/aws-fpga.git
cd aws-fpga
source sdk_setup.sh
sudo fpga-describe-local-image -S 0

# Install Vivado (AWS F1 compatible version)
echo "⚡ Installing Vivado..."
cd ~
wget https://download.xilinx.com/vivado/2021.2/xilinx_vivado_2021.2_0612_1430.tar.gz
tar -xzf xilinx_vivado_2021.2_0612_1430.tar.gz
cd xilinx_vivado_2021.2_0612_1430
sudo ./xsetup --batch Install --config /tmp/install_config.txt

# Create Vivado configuration
cat > /tmp/install_config.txt << EOF
Edition=Vitis
Version=2021.2
Destination=/opt/Xilinx
Install=1
EOF

# Set up Vivado environment
echo "source /opt/Xilinx/Vitis/2021.2/settings64.sh" >> ~/.bashrc
echo "export PATH=\$PATH:/opt/Xilinx/Vitis/2021.2/bin" >> ~/.bashrc

# Install Xilinx Runtime (XRT)
echo "🔧 Installing Xilinx Runtime..."
cd ~
git clone https://github.com/Xilinx/XRT.git
cd XRT
git checkout 2021.2
cd build
./build.sh
cd Release
sudo apt install -y ./xrt_*-Ubuntu*.deb

# Install AWS FPGA Runtime
echo "🔧 Installing AWS FPGA Runtime..."
cd ~/aws-fpga/sdk/userspace
make
sudo make install

# Set up udev rules for FPGA access
echo "🔐 Setting up udev rules..."
sudo tee /etc/udev/rules.d/99-fpga.rules > /dev/null << EOF
SUBSYSTEM=="fpga_manager", MODE="0666"
SUBSYSTEM=="fpga_region", MODE="0666"
SUBSYSTEM=="fpga_bridge", MODE="0666"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

# Install additional networking tools for packet capture
echo "🌐 Installing networking tools..."
sudo apt-get install -y \
    libpcap-dev \
    libnetfilter-queue-dev \
    nftables \
    iptables \
    conntrack-tools

# Set up hugepages for FPGA DMA
echo "💾 Setting up hugepages..."
echo 1024 | sudo tee /proc/sys/vm/nr_hugepages
echo 'vm.nr_hugepages = 1024' | sudo tee -a /etc/sysctl.conf

# Install Go (for Erigon)
# echo "🐹 Installing Go..."
# wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
# sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
# echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Create FPGA development environment
echo "🏗️ Setting up FPGA development environment..."
cd ~
mkdir -p fpga-workspace
cd fpga-workspace

# Clone your project
# if [ ! -d "bsc-mempool-monitor" ]; then
#     git clone https://github.com/your-username/bsc-mempool-monitor.git
# fi

# Set up environment variables
echo "export FPGA_WORKSPACE=~/fpga-workspace" >> ~/.bashrc
echo "export AWS_FPGA_REPO_DIR=~/aws-fpga" >> ~/.bashrc
echo "export VIVADO_PATH=/opt/Xilinx/Vitis/2021.2" >> ~/.bashrc

# Create FPGA build scripts
cat > ~/fpga-workspace/build_fpga.sh << 'EOF'
#!/bin/bash
set -e

echo "🔨 Building FPGA design..."

# Source environment
source ~/.bashrc
source ~/aws-fpga/sdk_setup.sh
source /opt/Xilinx/Vitis/2021.2/settings64.sh

# Navigate to project
cd ~/fpga-workspace/bsc-mempool-monitor/verilog

# Build the design
make build

echo "✅ FPGA build completed!"
EOF

chmod +x ~/fpga-workspace/build_fpga.sh

# Create deployment script
cat > ~/fpga-workspace/deploy_fpga.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Deploying FPGA design..."

# Source environment
source ~/.bashrc
source ~/aws-fpga/sdk_setup.sh

# Navigate to project
cd ~/fpga-workspace/bsc-mempool-monitor/verilog

# Program the FPGA
make program

# Verify programming
if lspci | grep -q Xilinx; then
    echo "✅ FPGA programmed successfully!"
    
    # Start the mempool monitor
    echo "Starting mempool monitor..."
    cd ..
    cargo run --release
else
    echo "❌ FPGA programming failed!"
    exit 1
fi
EOF

chmod +x ~/fpga-workspace/deploy_fpga.sh

# Create network monitoring script
cat > ~/fpga-workspace/monitor_network.sh << 'EOF'
#!/bin/bash

echo "🌐 Starting network monitoring..."

# Set up network interface for packet capture
sudo ip link set dev eth0 promisc on

# Start packet capture for Erigon P2P traffic
sudo tcpdump -i eth0 -w /tmp/erigon_p2p.pcap \
    -s 0 \
    'port 30303 or port 8545' &

# Monitor FPGA performance
while true; do
    echo "=== FPGA Status ==="
    sudo fpga-describe-local-image -S 0
    echo "=== Network Stats ==="
    sudo ethtool -S eth0 | grep -E "(rx_packets|tx_packets|rx_bytes|tx_bytes)"
    echo "=== Memory Usage ==="
    free -h
    echo "=================="
    sleep 10
done
EOF

chmod +x ~/fpga-workspace/monitor_network.sh

# # Create Erigon configuration
# cat > ~/fpga-workspace/erigon_config.toml << 'EOF'
# [Eth]
# NetworkId = 1
# SyncMode = "full"
# NoPruning = true
# NoPrefetch = true

# [Node]
# HTTPHost = "0.0.0.0"
# HTTPPort = 8545
# HTTPModules = ["eth", "net", "web3", "debug", "txpool"]
# HTTPCors = ["*"]
# HTTPVirtualHosts = ["*"]

# [Node.P2P]
# MaxPeers = 50
# BindAddr = ":30303"
# EnableMsgEvents = true

# [Metrics]
# HTTP = "0.0.0.0:6060"
# Enabled = true

# [TxPool]
# PriceLimit = 1
# EOF

# Create systemd service for automatic startup
# sudo tee /etc/systemd/system/fpga-mempool-monitor.service > /dev/null << EOF
# [Unit]
# Description=FPGA Mempool Monitor
# After=network.target

# [Service]
# Type=simple
# User=ubuntu
# WorkingDirectory=/home/ubuntu/fpga-workspace
# Environment=PATH=/home/ubuntu/.cargo/bin:/usr/local/go/bin:/opt/Xilinx/Vitis/2021.2/bin
# ExecStart=/home/ubuntu/fpga-workspace/deploy_fpga.sh
# Restart=always
# RestartSec=10

# [Install]
# WantedBy=multi-user.target
# EOF

# # Enable the service
# sudo systemctl enable fpga-mempool-monitor.service

# # Create performance monitoring script
# cat > ~/fpga-workspace/performance_monitor.sh << 'EOF'
# #!/bin/bash

# echo "📊 Starting performance monitoring..."

# Monitor system resources
while true; do
    echo "=== $(date) ==="
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    
    echo "Memory Usage:"
    free -h | grep Mem
    
    echo "FPGA Status:"
    sudo fpga-describe-local-image -S 0
    
    echo "Network Traffic:"
    sudo cat /proc/net/dev | grep eth0
    
    echo "Active Connections:"
    ss -tuln | grep -E "(30303|8545)"
    
    echo "=================="
    sleep 30
done
EOF

chmod +x ~/fpga-workspace/performance_monitor.sh

# Set up log rotation
# sudo tee /etc/logrotate.d/fpga-mempool-monitor > /dev/null << EOF
# /home/ubuntu/fpga-workspace/*.log {
#     daily
#     missingok
#     rotate 7
#     compress
#     notifempty
#     create 644 ubuntu ubuntu
# }
# EOF
echo "✅ AWS F1 setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Reboot the system: sudo reboot"
echo "2. After reboot, source environment: source ~/.bashrc"
echo "3. Build FPGA design: ~/fpga-workspace/build_fpga.sh"
echo "4. Deploy to FPGA: ~/fpga-workspace/deploy_fpga.sh"
echo "5. Monitor performance: ~/fpga-workspace/performance_monitor.sh"
echo ""
echo "🔧 Useful commands:"
echo "- Check FPGA status: sudo fpga-describe-local-image -S 0"
echo "- Monitor network: ~/fpga-workspace/monitor_network.sh"
echo "- Start Erigon: erigon --config ~/fpga-workspace/erigon_config.toml"
echo "- View logs: journalctl -u fpga-mempool-monitor -f"
echo ""
echo "⚠️  Important: Make sure to configure your AWS credentials:"
echo "aws configure"
