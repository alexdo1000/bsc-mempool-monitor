# Using Xilinx Vivado (most common for high-end FPGAs)
vivado -mode batch -source build_script.tcl

# Or using Intel Quartus (for Intel/Altera FPGAs)
quartus_sh --flow compile mempool_monitor_top