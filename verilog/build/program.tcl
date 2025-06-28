# program.tcl:
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices [get_hw_devices xcu250_0] -bit_file ./build/mempool_monitor.bit