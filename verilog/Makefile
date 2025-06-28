FPGA_PART = xcu250-figd2104-2L-e
TOP_MODULE = mempool_monitor_top

build:
	vivado -mode batch -source scripts/build.tcl

program:
	vivado -mode batch -source scripts/program.tcl

flash:
	vivado -mode batch -source scripts/flash.tcl

clean:
	rm -rf build/

.PHONY: build program flash clean