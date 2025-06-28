# Program flash memory so FPGA boots your design automatically
vivado -mode batch -source flash_program.tcl


# #!/bin/bash
# # deploy_prod.sh

# # Build the design
# make build

# # Program the flash memory (survives power cycles)
# make flash

# # Reset the FPGA to load from flash
# make reset

# # Verify the design is running
# make verify