# Vivado build script for AWS F1 FPGA
# This script builds the mempool monitor design

set project_name "mempool_monitor"
set project_dir "./build"
set top_module "mempool_monitor_top"
set fpga_part "xcu250-figd2104-2L-e"

# Create project
create_project $project_name $project_dir -part $fpga_part -force

# Set project properties
set_property board_part xilinx.com:au250:part0:1.4 [current_project]
set_property target_language Verilog [current_project]

# Add source files
add_files -norecurse [list \
    "../src/mempoolMonitor.v" \
    "../src/networkInterface.v" \
    "../src/transactionParser.v" \
]

# Set top module
set_property top $top_module [current_fileset]
set_property top_file "../src/mempoolMonitor.v" [current_fileset]

# Create IP cores if needed
# create_ip -name axi_dma -vendor xilinx.com -library ip -version 7.1 -module_name axi_dma_0
# set_property -dict [list CONFIG.c_include_sg {0} CONFIG.c_sg_length_width {16}] [get_ips axi_dma_0]
# generate_target all [get_ips]

# Create constraints file
set constraints_file "$project_dir/${project_name}.xdc"
set fp [open $constraints_file w]

puts $fp "# Clock constraints"
puts $fp "create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} \[get_ports sys_clk\]"
puts $fp ""
puts $fp "# Reset constraints"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports sys_rst_n\]"
puts $fp ""
puts $fp "# Network interface constraints"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports eth_rx_data\[*\]\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports eth_rx_valid\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports eth_rx_sof\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports eth_rx_eof\]"
puts $fp ""
puts $fp "# AXI interface constraints"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports m_axi_awaddr\[*\]\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports m_axi_awlen\[*\]\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports m_axi_awvalid\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports m_axi_awready\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports m_axi_wdata\[*\]\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports m_axi_wvalid\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports m_axi_wready\]"
puts $fp "set_property IOSTANDARD LVCMOS18 \[get_ports m_axi_wlast\]"

close $fp

add_files -fileset constrs_1 -norecurse $constraints_file

# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Check synthesis status
if {[get_property PROGRESS [get_runs synth_1]] == "100%"} {
    puts "Synthesis completed successfully"
} else {
    puts "Synthesis failed"
    exit 1
}

# Run implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Check implementation status
if {[get_property PROGRESS [get_runs impl_1]] == "100%"} {
    puts "Implementation completed successfully"
} else {
    puts "Implementation failed"
    exit 1
}

# Generate bitstream
write_bitstream -force "$project_dir/${project_name}.bit"

puts "Build completed successfully!"
puts "Bitstream location: $project_dir/${project_name}.bit" 