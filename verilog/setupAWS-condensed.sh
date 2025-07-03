#!/bin/bash
set -e

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

# Install AWS FPGA SDK
echo "🔧 Installing AWS FPGA SDK..."
cd ~
git clone https://github.com/aws/aws-fpga.git
cd aws-fpga
git branch f1_xdma_shell
source sdk_setup.sh
sudo fpga-describe-local-image -S 0


