# Vivado programming script for AWS F1 FPGA
# This script programs the FPGA with the mempool monitor design

set project_name "mempool_monitor"
set project_dir "./build"
set bitstream_file "$project_dir/${project_name}.bit"

# Check if bitstream exists
if {![file exists $bitstream_file]} {
    puts "Error: Bitstream file not found: $bitstream_file"
    puts "Please run the build script first"
    exit 1
}

# Open hardware manager
open_hw_manager

# Connect to hardware
connect_hw_server
open_hw_target

# Get the FPGA device
set hw_device [lindex [get_hw_devices] 0]
puts "Programming device: $hw_device"

# Set the bitstream file
set_property PROGRAM.FILE $bitstream_file $hw_device

# Program the FPGA
puts "Programming FPGA..."
program_hw_devices $hw_device

# Verify programming
puts "Verifying programming..."
refresh_hw_device $hw_device

puts "FPGA programming completed successfully!"

# Close hardware manager
close_hw_manager 