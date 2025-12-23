#!/bin/bash
#******************************************************
# Build script for Virtual CRT FPGA Project
# Wraps Makefile with additional convenience functions
#******************************************************

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

function print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

function print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

function check_tools() {
    print_header "Checking Required Tools"

    local missing_tools=0

    # Check for Gowin tools
    if [ -z "$GOWIN_HOME" ]; then
        print_warning "GOWIN_HOME not set. Please set it to your Gowin EDA installation path"
        print_warning "Example: export GOWIN_HOME=/Applications/Gowin"
        missing_tools=1
    else
        echo "GOWIN_HOME: $GOWIN_HOME"
    fi

    # Check for optional simulation tools
    if command -v iverilog &> /dev/null; then
        echo "✓ iverilog found: $(iverilog -V | head -n1)"
    else
        print_warning "iverilog not found (optional, needed for simulation)"
    fi

    if command -v verilator &> /dev/null; then
        echo "✓ verilator found: $(verilator --version | head -n1)"
    else
        print_warning "verilator not found (optional, needed for linting)"
    fi

    if [ $missing_tools -eq 1 ]; then
        print_error "Missing required tools. Please install them first."
        return 1
    fi

    return 0
}

function build_all() {
    print_header "Building Complete Project"
    make all
    echo -e "${GREEN}Build complete!${NC}"
}

function build_and_program() {
    print_header "Building and Programming FPGA"
    make all
    make program
    echo -e "${GREEN}FPGA programmed successfully!${NC}"
}

function run_simulation() {
    print_header "Running Simulation"
    make sim
}

function show_help() {
    cat << EOF
Virtual CRT Build Script

Usage: $0 [command]

Commands:
    check       Check for required tools
    build       Build bitstream
    program     Build and program FPGA
    sim         Run simulation
    clean       Clean build artifacts
    lint        Run linter
    help        Show this help

Environment Variables:
    GOWIN_HOME  Path to Gowin EDA installation

EOF
}

# Main script logic
case "${1:-build}" in
    check)
        check_tools
        ;;
    build)
        check_tools && build_all
        ;;
    program)
        check_tools && build_and_program
        ;;
    sim)
        run_simulation
        ;;
    clean)
        make clean
        ;;
    lint)
        make lint
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
