# BSC Mempool Monitor - AWS F1 FPGA Setup

This project implements a high-performance mempool monitoring system using AWS F1 FPGA instances to detect and frontrun transactions on the Binance Smart Chain (BSC) network using Erigon full nodes.

## 🏗️ Architecture Overview

The system consists of:

1. **FPGA Hardware Layer**: Custom Verilog modules for high-speed packet processing
2. **Network Interface**: P2P protocol parsing and transaction extraction
3. **Transaction Parser**: RLP decoding and transaction analysis
4. **Host Software**: Rust-based application for MEV strategies
5. **Erigon Integration**: Full node for blockchain data

## 🚀 Quick Setup

### Prerequisites

- AWS F1 instance (f1.2xlarge or larger)
- Ubuntu 20.04 LTS
- AWS CLI configured with appropriate permissions

### 1. Initial Setup

```bash
# Clone the repository
git clone https://github.com/your-username/bsc-mempool-monitor.git
cd bsc-mempool-monitor

# Make setup script executable
chmod +x verilog/setupAWS.sh

# Run the comprehensive setup
./verilog/setupAWS.sh
```

### 2. Reboot and Environment Setup

```bash
# Reboot to apply all changes
sudo reboot

# After reboot, source the environment
source ~/.bashrc
```

### 3. Build and Deploy

```bash
# Build the FPGA design
~/fpga-workspace/build_fpga.sh

# Deploy to FPGA
~/fpga-workspace/deploy_fpga.sh
```

## 📁 Project Structure

```
bsc-mempool-monitor/
├── verilog/                    # FPGA hardware design
│   ├── src/                   # Verilog source files
│   │   ├── mempoolMonitor.v   # Top-level module
│   │   ├── networkInterface.v # P2P network interface
│   │   └── transactionParser.v # Transaction parsing logic
│   ├── scripts/               # Build and deployment scripts
│   ├── build/                 # Generated build files
│   └── setupAWS.sh           # AWS F1 setup script
├── src/                       # Rust host software
├── fullnode/                  # Erigon configuration
└── README.md                 # This file
```

## 🔧 FPGA Design Details

### Top-Level Module (`mempoolMonitor.v`)

The main FPGA module that orchestrates:
- P2P network packet processing
- Transaction parsing and validation
- AXI interface for host communication
- Real-time transaction analysis

### Network Interface (`networkInterface.v`)

Handles:
- Ethernet frame parsing
- P2P protocol decoding
- Message type identification
- Payload extraction

### Transaction Parser (`transactionParser.v`)

Implements:
- RLP (Recursive Length Prefix) decoding
- Transaction structure parsing
- Gas price analysis
- Address extraction

## 🌐 Network Integration

### Erigon Configuration

The system integrates with Erigon full nodes to:
- Monitor P2P network traffic
- Extract transaction data
- Analyze mempool contents
- Detect profitable opportunities

### P2P Protocol Support

Supports Ethereum P2P protocol features:
- Node discovery
- Block propagation
- Transaction broadcasting
- Network synchronization

## ⚡ Performance Characteristics

- **Latency**: < 1μs transaction processing
- **Throughput**: 10+ Gbps network processing
- **Memory**: 8GB DDR4 with DMA access
- **FPGA**: Xilinx VU250 with 1.7M LUTs

## 🔍 Monitoring and Debugging

### Performance Monitoring

```bash
# Monitor system performance
~/fpga-workspace/performance_monitor.sh

# Monitor network traffic
~/fpga-workspace/monitor_network.sh

# Check FPGA status
sudo fpga-describe-local-image -S 0
```

### Log Analysis

```bash
# View system logs
journalctl -u fpga-mempool-monitor -f

# Check Erigon logs
tail -f ~/.local/share/erigon/erigon.log
```

## 🛠️ Development Workflow

### 1. Modify Verilog Code

```bash
cd verilog/src
# Edit your Verilog files
```

### 2. Build and Test

```bash
cd verilog
make build
make program
```

### 3. Flash for Persistence

```bash
make flash
```

## 🔐 Security Considerations

- **Network Isolation**: Use VPC and security groups
- **Access Control**: Implement proper authentication
- **Monitoring**: Log all activities for audit
- **Updates**: Keep FPGA bitstreams updated

## 📊 Metrics and Analytics

The system provides:
- Transaction processing rates
- Network latency measurements
- FPGA utilization statistics
- MEV opportunity detection

## 🚨 Troubleshooting

### Common Issues

1. **FPGA Programming Fails**
   ```bash
   sudo fpga-describe-local-image -S 0
   sudo fpga-clear-local-image -S 0
   ```

2. **Network Interface Issues**
   ```bash
   sudo ip link set dev eth0 promisc on
   sudo ethtool -S eth0
   ```

3. **Build Failures**
   ```bash
   source ~/.bashrc
   source ~/aws-fpga/sdk_setup.sh
   source /opt/Xilinx/Vitis/2021.2/settings64.sh
   ```

### Debug Commands

```bash
# Check FPGA status
lspci | grep Xilinx

# Monitor system resources
htop
iotop

# Check network connections
ss -tuln | grep -E "(30303|8545)"

# View kernel messages
dmesg | tail -20
```

## 📈 Scaling Considerations

- **Multiple FPGAs**: Use multiple F1 instances
- **Load Balancing**: Distribute network traffic
- **Geographic Distribution**: Deploy across regions
- **Redundancy**: Implement failover mechanisms

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

This software is for educational and research purposes. Users are responsible for complying with all applicable laws and regulations regarding blockchain trading and MEV activities.

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review AWS F1 documentation

---

**Note**: This setup requires significant computational resources and should be used responsibly in accordance with network policies and regulations. 