# virtual-crt

Hardware + software implementation of virtual display interface to CRT TV, with NES artifacts.

An FPGA-based system that converts digital video input (via USB-C) to authentic NTSC composite video for display on CRT televisions, with support for NES PPU (2C02) artifacts.

## Hardware

- **Platform:** INEX Tang Nano 4K (Gowin GW1NSR-4C FPGA)
- **CRT Display:** Sharp 21F-PT220
- **NTSC Video Generator:** Modular architecture, switchable between multiple generators
- **Video Output:** 8-bit DAC (Luma + Chroma + Sync)

## Features

- **NTSC Video Generation**
  - Accurate NTSC timing (525-line, 59.94 Hz)
  - RGB to YIQ color space conversion
  - Quadrature chroma modulation
  - Color subcarrier: 3.579545 MHz

- **Modular Generator Architecture**
  - Mode 0: Basic NTSC generator
  - Mode 1: NES PPU (2C02) accurate timing (TODO)
  - Mode 2: Custom with enhanced artifacts (TODO)

- **Test Pattern Generator**
  - 320×240 color bars (8 colors)
  - Placeholder for USB video input

## Quick Start

### Prerequisites

1. Install [Gowin EDA](http://www.gowinsemi.com.cn/) (v1.9.8+)
2. Set `GOWIN_HOME` environment variable
3. Optional: Install `iverilog` and `gtkwave` for simulation

### Build and Program

```bash
# Check prerequisites
./tools/build.sh check

# Build bitstream
make all

# Program FPGA
make program
```

### Important Note

**Before building**, you must generate the PLL IP core using Gowin IDE:
1. Open Gowin IDE → IP Core Generator → PLL
2. Configure clocks (see `doc/BUILD_GUIDE.md`)
3. Save to `hdl/ip/pll.v`

See detailed instructions in [`doc/BUILD_GUIDE.md`](doc/BUILD_GUIDE.md)

## Project Structure

```
virtual-crt/
├── hdl/
│   ├── rtl/              # Verilog source files
│   └── ip/               # IP cores (PLL)
├── constraints/
│   ├── tang_nano_4k.cst  # Pin constraints
│   └── timing.sdc        # Timing constraints
├── sim/
│   ├── tb/               # Testbenches
│   └── waves/            # Simulation waveforms
├── doc/
│   ├── architecture/     # Architecture documentation
│   └── BUILD_GUIDE.md    # Build instructions
├── tools/                # Build scripts
├── Makefile              # Build automation
└── README.md
```

## HDL Modules

- **virtual_crt_top.v** - Top-level module
- **clock_manager.v** - PLL wrapper and clock generation
- **reset_sync.v** - Reset synchronizer
- **ntsc_video_generator.v** - Main NTSC generator
- **rgb_to_yiq.v** - RGB to YIQ color space converter
- **ntsc_timing_gen.v** - NTSC sync signal generator
- **chroma_modulator.v** - I/Q quadrature modulator
- **usb_video_interface.v** - USB video input (test pattern stub)

## Architecture

For detailed architecture documentation, see [`doc/architecture/ARCHITECTURE.md`](doc/architecture/ARCHITECTURE.md)

## Software Architecture

Implement software interface for external display through USB-C interface of Tang Nano 4K for input video signal.
Implement FPGA interface for NTSC video generator - modular architecture allowing switching between different generator implementations.

## NTSC Video Generators

### NTSC (2C02) References

- [Clock Reference Chart](https://www.nesdev.org/wiki/Cycle_reference_chart)
- [NTSC Video](https://www.nesdev.org/wiki/NTSC_video)
- [NES PPU](https://www.nesdev.org/wiki/PPU)

## Development

### Simulation

```bash
# Run testbenches
make sim

# View waveforms
gtkwave sim/waves/rgb_to_yiq.vcd
```

### Linting

```bash
make lint
```

## Hardware Setup

Build 8-bit R-2R ladder DACs for video output:
- **Luma Channel:** Pins 25-32
- **Chroma Channel:** Pins 33-40
- **Sync:** Pin 41

See `constraints/tang_nano_4k.cst` for complete pin mapping.

## Current Status

- [x] Project structure initialized
- [x] Clock management (PLL wrapper)
- [x] NTSC timing generator
- [x] RGB to YIQ conversion
- [x] Chroma modulator
- [x] Test pattern generator
- [ ] PLL IP core configuration
- [ ] Hardware DAC circuit
- [ ] USB video input implementation
- [ ] NES PPU (2C02) mode
- [ ] CRT testing and validation

## Next Steps

1. Generate PLL IP core in Gowin IDE
2. Build DAC hardware circuit
3. Test on actual CRT display
4. Implement USB video input
5. Add NES PPU accurate mode

## License

TBD

## References

- [Gowin FPGA Documentation](http://www.gowinsemi.com.cn/)
- [Tang Nano 4K](http://www.gowinsemi.com.cn/)
- [NTSC Video Standard](https://www.nesdev.org/wiki/NTSC_video)
- [NES PPU Reference](https://www.nesdev.org/wiki/PPU)


