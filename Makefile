#******************************************************
# Makefile for Virtual CRT FPGA Project
# Target: Tang Nano 4K (GW1NSR-4C)
# Toolchain: Gowin EDA
#******************************************************

#------------------------------------------------------
# Project Configuration
#------------------------------------------------------
PROJECT_NAME = virtual_crt
TOP_MODULE = virtual_crt_top
DEVICE = GW1NSR-LV4CQN48PC7/I6
FAMILY = GW1NSR-4C

#------------------------------------------------------
# Directories
#------------------------------------------------------
HDL_DIR = hdl/rtl
IP_DIR = hdl/ip
SIM_DIR = sim/tb
CONSTRAINT_DIR = constraints
BUILD_DIR = build
WAVES_DIR = sim/waves

#------------------------------------------------------
# Source Files
#------------------------------------------------------
VERILOG_SOURCES = $(wildcard $(HDL_DIR)/*.v)
CONSTRAINT_CST = $(CONSTRAINT_DIR)/tang_nano_4k.cst
CONSTRAINT_SDC = $(CONSTRAINT_DIR)/timing.sdc

#------------------------------------------------------
# Gowin EDA Tool Paths
# Adjust these paths according to your installation
#------------------------------------------------------
GOWIN_HOME ?= /Applications/Gowin
GWINC = $(GOWIN_HOME)/IDE/bin/gwinc
PROGRAMMER = $(GOWIN_HOME)/Programmer/bin/programmer_cli

#------------------------------------------------------
# Build Targets
#------------------------------------------------------
.PHONY: all clean synthesize pnr bitstream program sim help

all: bitstream

# Help target
help:
	@echo "Virtual CRT FPGA Build System"
	@echo "=============================="
	@echo "Targets:"
	@echo "  all        - Build complete bitstream (default)"
	@echo "  synthesize - Run synthesis only"
	@echo "  pnr        - Run place and route"
	@echo "  bitstream  - Generate bitstream file"
	@echo "  program    - Program FPGA via USB"
	@echo "  sim        - Run simulation"
	@echo "  clean      - Clean build artifacts"
	@echo ""
	@echo "Environment Variables:"
	@echo "  GOWIN_HOME - Path to Gowin EDA installation"

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Synthesis
synthesize: $(BUILD_DIR)
	@echo "=== Running Synthesis ==="
	@cd $(BUILD_DIR) && \
	$(GWINC) --project=$(PROJECT_NAME) \
	         --top=$(TOP_MODULE) \
	         --device=$(DEVICE) \
	         --syn

# Place and Route
pnr: synthesize
	@echo "=== Running Place and Route ==="
	@cd $(BUILD_DIR) && \
	$(GWINC) --project=$(PROJECT_NAME) \
	         --pnr

# Generate bitstream
bitstream: pnr
	@echo "=== Generating Bitstream ==="
	@cd $(BUILD_DIR) && \
	$(GWINC) --project=$(PROJECT_NAME) \
	         --bitstream
	@echo "Bitstream generated: $(BUILD_DIR)/$(PROJECT_NAME).fs"

# Program FPGA
program: bitstream
	@echo "=== Programming FPGA ==="
	$(PROGRAMMER) --device $(DEVICE) \
	              --fsFile $(BUILD_DIR)/$(PROJECT_NAME).fs \
	              --run 2

# Simulation with iverilog
sim:
	@echo "=== Running Simulation ==="
	@mkdir -p $(WAVES_DIR)
	@cd $(SIM_DIR) && \
	iverilog -g2012 -o $(WAVES_DIR)/sim.vvp \
	         -I../../$(HDL_DIR) \
	         ../../$(HDL_DIR)/*.v \
	         *_tb.v
	@cd $(WAVES_DIR) && vvp sim.vvp
	@echo "Waveform: $(WAVES_DIR)/dump.vcd"
	@echo "View with: gtkwave $(WAVES_DIR)/dump.vcd"

# Clean build artifacts
clean:
	@echo "=== Cleaning Build Artifacts ==="
	@rm -rf $(BUILD_DIR)/*
	@rm -rf $(WAVES_DIR)/*
	@echo "Clean complete"

#------------------------------------------------------
# Project file generation
#------------------------------------------------------
.PHONY: init-project

init-project:
	@echo "Initializing Gowin project files..."
	@echo "Note: You may need to use Gowin IDE to create initial .gprj file"
	@echo "This Makefile assumes project configuration is already set up"

#------------------------------------------------------
# Lint/Check
#------------------------------------------------------
.PHONY: lint

lint:
	@echo "=== Running Verilator Lint ==="
	@verilator --lint-only -Wall \
	           -I$(HDL_DIR) \
	           $(VERILOG_SOURCES) \
	           --top-module $(TOP_MODULE)

#------------------------------------------------------
# Report timing
#------------------------------------------------------
.PHONY: timing

timing: pnr
	@echo "=== Timing Report ==="
	@cat $(BUILD_DIR)/$(PROJECT_NAME)_timing.rpt
