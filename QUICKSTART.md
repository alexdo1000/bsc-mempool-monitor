# 🚀 Quick Start Guide - AWS F1 FPGA Setup

This guide will get you up and running with FPGA-based mempool monitoring on AWS F1 in under 30 minutes.

## Prerequisites

✅ **AWS F1 Instance**: f1.2xlarge or larger  
✅ **Ubuntu 20.04 LTS**: Pre-installed on F1 instances  
✅ **AWS CLI**: Configured with F1 permissions  

## Step 1: Launch AWS F1 Instance

1. **Go to AWS Console** → EC2 → Launch Instance
2. **Choose AMI**: `FPGA Developer AMI - 1.12.2-40257ab5-6688-4c95-97d1-e51a4b1c5d8e`
3. **Instance Type**: `f1.2xlarge` (minimum)
4. **Storage**: 100GB GP3 (recommended)
5. **Security Groups**: Allow SSH (port 22) and HTTP (port 80)

## Step 2: Connect and Setup

```bash
# SSH into your instance
ssh -i your-key.pem ubuntu@your-instance-ip

# Clone the repository
git clone https://github.com/your-username/bsc-mempool-monitor.git
cd bsc-mempool-monitor

# Run the automated setup (takes 15-20 minutes)
./verilog/setupAWS.sh
```

## Step 3: Reboot and Verify

```bash
# Reboot to apply all changes
sudo reboot

# Wait 2 minutes, then reconnect
ssh -i your-key.pem ubuntu@your-instance-ip

# Source environment
source ~/.bashrc

# Verify FPGA is detected
lspci | grep Xilinx
```

## Step 4: Build and Deploy

```bash
# Build the FPGA design (takes 10-15 minutes)
~/fpga-workspace/build_fpga.sh

# Deploy to FPGA
~/fpga-workspace/deploy_fpga.sh
```

## Step 5: Start Monitoring

```bash
# Start Erigon full node
erigon --config ~/fpga-workspace/erigon_config.toml &

# Monitor performance
~/fpga-workspace/performance_monitor.sh
```

## ✅ Verification Checklist

- [ ] FPGA detected: `lspci | grep Xilinx`
- [ ] Vivado installed: `which vivado`
- [ ] AWS FPGA SDK: `ls ~/aws-fpga`
- [ ] Rust installed: `rustc --version`
- [ ] Go installed: `go version`
- [ ] Erigon built: `which erigon`
- [ ] FPGA programmed: `sudo fpga-describe-local-image -S 0`

## 🚨 Common Issues & Solutions

### Issue: "FPGA not detected"
```bash
sudo fpga-describe-local-image -S 0
sudo fpga-clear-local-image -S 0
sudo reboot
```

### Issue: "Vivado not found"
```bash
source /opt/Xilinx/Vitis/2021.2/settings64.sh
echo 'source /opt/Xilinx/Vitis/2021.2/settings64.sh' >> ~/.bashrc
```

### Issue: "Build fails"
```bash
source ~/.bashrc
source ~/aws-fpga/sdk_setup.sh
cd ~/fpga-workspace/bsc-mempool-monitor/verilog
make clean && make build
```

## 📊 Performance Monitoring

```bash
# Real-time monitoring
~/fpga-workspace/performance_monitor.sh

# Network traffic
~/fpga-workspace/monitor_network.sh

# System resources
htop
```

## 🔧 Next Steps

1. **Configure Erigon**: Edit `~/fpga-workspace/erigon_config.toml`
2. **Customize FPGA Logic**: Modify `verilog/src/` files
3. **Add MEV Strategies**: Extend the Rust application
4. **Scale Up**: Deploy multiple F1 instances

## 📞 Need Help?

- Check the full [README.md](README.md)
- Review [troubleshooting section](README.md#troubleshooting)
- Create an issue on GitHub

---

**⏱️ Total Setup Time**: ~30 minutes  
**💰 Estimated Cost**: $1.65/hour (f1.2xlarge)  
**🎯 Performance**: <1μs transaction processing 