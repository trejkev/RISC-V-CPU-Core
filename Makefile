IVERILOG = iverilog # Icarus Verilog - Executable generator
VVP      = vvp      # Verilog Virtual Processor - Simulator
GTKWAVE  = gtkwave

IVERILOG_FLAGS = -g2012 -Wall

PC   = program_counter
CORE = riscv_core

UT_DIR    = sim/unit_test
CORE_DIR  = rtl/core
UT_TB_DIR = tb/unit


##################
# Program Counter
##################
PC_RTL = $(CORE_DIR)/$(PC).sv
PC_TB  = $(UT_TB_DIR)/$(PC)_tb.sv
PC_SIM_EXE  = $(UT_DIR)/$(PC)/$(PC)
VCD_FILE    = $(UT_DIR)/$(PC)/$(PC).vcd

pc_unittest_exe: pc_unittest_clean_sim
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(PC_SIM_EXE) $(PC_RTL) $(PC_TB)

pc_unittest_sim: pc_unittest_exe
	$(VVP) $(PC_SIM_EXE)

pc_unittest_wave: pc_unittest_sim
	$(GTKWAVE) $(VCD_FILE)

pc_unittest_clean_sim:
	rm -rf $(UT_DIR)/$(PC)/*
