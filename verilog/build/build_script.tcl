# Create project
create_project mempool_monitor ./build -part xcu250-figd2104-2L-e

# Add your Verilog files
add_files {
    networkinterface.v
    tx_parser.v  
    mempoolmonitor.v
}

# Set top module
set_property top mempool_monitor_top [current_fileset]

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Run implementation (place & route)
launch_runs impl_1 -jobs 8
wait_on_run impl_1

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1