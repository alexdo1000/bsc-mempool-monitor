#!/bin/bash
set -e

echo "🚀 Deploying MEV FPGA..."

# Build the design
echo "Building..."
make build

# Program the FPGA
echo "Programming FPGA..."
make program

# Test the deployment
echo "Testing..."
if lspci | grep -q Xilinx; then
    echo "✅ FPGA programmed successfully!"
    
    # Start your CPU-side software
    echo "Starting MEV bot..."
    cd ../software
    cargo run --release
else
    echo "❌ FPGA programming failed!"
    exit 1
fi