#!/bin/bash
# deploy_dev.sh

echo "Building FPGA design..."
vivado -mode batch -source build.tcl

if [ $? -eq 0 ]; then
    echo "Programming FPGA..."
    vivado -mode batch -source program.tcl
    echo "FPGA programmed successfully!"
else
    echo "Build failed!"
    exit 1
fi