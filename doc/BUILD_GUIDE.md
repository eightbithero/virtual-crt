# Virtual CRT - Build Guide

## Prerequisites

### Hardware

- **FPGA Board:** Tang Nano 4K (Gowin GW1NSR-4C)
- **CRT Display:** NTSC-compatible CRT television
- **USB Cable:** USB-C to USB-A for programming
- **Video Cable:** Composite video cable (RCA)
- **DAC Circuit:** 8-bit resistor ladder DACs (see Hardware Setup)

### Software

1. **Gowin EDA** (v1.9.8 or later)
   - Download from: http://www.gowinsemi.com.cn/
   - Install location: `/Applications/Gowin` (macOS) or `C:\Gowin` (Windows)
   - Set `GOWIN_HOME` environment variable

2. **Optional Tools:**
   - **iverilog** - For simulation (install via Homebrew/apt)
   - **gtkwave** - For waveform viewing
   - **verilator** - For linting

### Installation (macOS/Linux)

```bash
# Install simulation tools
brew install icarus-verilog gtkwave verilator

# Set GOWIN_HOME
export GOWIN_HOME=/Applications/Gowin
echo 'export GOWIN_HOME=/Applications/Gowin' >> ~/.zshrc

# Verify installation
./tools/build.sh check
```

## Project Structure

```
virtual-crt/
├── hdl/
│   ├── rtl/           # Verilog source files
│   └── ip/            # IP cores (PLL, etc.)
├── constraints/
│   ├── tang_nano_4k.cst  # Pin constraints
│   └── timing.sdc        # Timing constraints
├── sim/
│   ├── tb/            # Testbenches
│   └── waves/         # Waveform outputs
├── doc/               # Documentation
├── tools/             # Build scripts
├── build/             # Build outputs (generated)
├── Makefile           # Build automation
└── README.md
```

## Build Process

### Step 1: Configure PLL IP Core

**Important:** The PLL must be configured using Gowin IDE first.

1. Open Gowin IDE
2. Tools → IP Core Generator → PLL
3. Configure:
   - **Input Clock:** 27 MHz
   - **Output Clock 0:** 21.477272 MHz (NTSC master clock)
   - **Output Clock 1:** 48 MHz (USB clock)
   - **Output Clock 2:** 3.579545 MHz (NTSC pixel clock)
4. Generate and save to `hdl/ip/pll.v`
5. Update `clock_manager.v` to instantiate the PLL

### Step 2: Build Using Makefile

```bash
# Build complete bitstream
make all

# Or use build script
./tools/build.sh build

# Clean build artifacts
make clean
```

### Step 3: Program FPGA

```bash
# Program via USB
make program

# Or manually using Gowin Programmer
# File → Open → select build/virtual_crt.fs
# Click "Program/Configure"
```

## Simulation

### Run Testbenches

```bash
# Run all simulations
make sim

# Or manually run specific testbench
cd sim/tb
iverilog -g2012 -o ../waves/sim.vvp \
    -I../../hdl/rtl \
    ../../hdl/rtl/*.v \
    rgb_to_yiq_tb.v
cd ../waves
vvp sim.vvp
```

### View Waveforms

```bash
# View with GTKWave
gtkwave sim/waves/rgb_to_yiq.vcd
```

## Hardware Setup

### Pin Connections

Refer to `constraints/tang_nano_4k.cst` for complete pin mapping.

#### NTSC Video Output DAC

Build 8-bit R-2R ladder DACs for Luma and Chroma channels:

**Luma Channel (Y):**
- Pins: 25-32 (ntsc_luma[7:0])
- Output: 0-1V video signal

**Chroma Channel (C):**
- Pins: 33-40 (ntsc_chroma[7:0])
- Output: Modulated color subcarrier

**Sync:**
- Pin: 41 (ntsc_sync)
- Output: Composite sync (H+V)

**R-2R Ladder Circuit:**
```
        R     R     R     R
MSB ───┳───┳───┳───┳───┳──── VOUT
       │   │   │   │   │
      2R  2R  2R  2R  2R
       │   │   │   │   │
      GND GND GND GND GND
```

Use precision resistors:
- R = 10kΩ (±1%)
- 2R = 20kΩ (±1%)

#### CRT Connection

1. Mix Luma, Chroma, and Sync signals (or keep separate for S-Video)
2. Add 75Ω termination resistor
3. Connect to RCA composite input on CRT

### USB-C Interface

**Current Status:** Placeholder only

Future implementation will use USB-C pins for DisplayPort Alt Mode or USB video input.

## Verification

### LED Status Indicators

After programming, observe the LEDs:

- **LED[0]:** Should blink at ~1.6 Hz (heartbeat)
- **LED[1]:** Should be ON (PLL locked)
- **LED[2-3]:** Should be ON (resets released)
- **LED[4-5]:** Should toggle (video sync active)

### Video Output

Expected output on CRT:
- **Color bars pattern** (8 vertical bars)
- Colors (L→R): White, Yellow, Cyan, Green, Magenta, Red, Blue, Black
- Resolution: 320×240 scaled to NTSC

## Troubleshooting

### Build Errors

**Error:** `GOWIN_HOME not set`
```bash
export GOWIN_HOME=/Applications/Gowin
```

**Error:** PLL module not found
- Generate PLL IP using Gowin IDE (see Step 1)

### Programming Issues

**Error:** Device not found
- Check USB connection
- Install FTDI drivers
- Try different USB port

### No Video Output

1. Check LED[1] - PLL must be locked
2. Verify DAC circuit connections
3. Check CRT input selection (AV/Video)
4. Measure DAC output with oscilloscope

### Simulation Failures

**Error:** Module not found
```bash
# Ensure all RTL files are in hdl/rtl/
ls hdl/rtl/*.v
```

**Error:** VCD file not generated
```bash
# Check $dumpfile path in testbench
# Ensure sim/waves/ directory exists
mkdir -p sim/waves
```

## Development Workflow

### 1. Modify HDL

Edit source files in `hdl/rtl/`

### 2. Simulate

```bash
make sim
gtkwave sim/waves/*.vcd
```

### 3. Lint

```bash
make lint
```

### 4. Build

```bash
make all
```

### 5. Program

```bash
make program
```

### 6. Test on Hardware

Verify on CRT display and debug with LEDs/oscilloscope

## Performance Metrics

### Resource Utilization

Check after synthesis:
```bash
cat build/virtual_crt_utilization.rpt
```

Target: < 50% of GW1NSR-4C resources

### Timing Analysis

```bash
make timing
cat build/virtual_crt_timing.rpt
```

Ensure all timing constraints are met.

## Next Steps

1. **Implement PLL IP** - Critical for proper clock generation
2. **Build DAC hardware** - Required for video output
3. **Test on CRT** - Verify video quality
4. **Implement USB video** - Replace test pattern with real input
5. **Add NES PPU mode** - Authentic retro artifacts

## References

- [Gowin FPGA User Guide](http://www.gowinsemi.com.cn/)
- [Tang Nano 4K Schematic](http://www.gowinsemi.com.cn/)
- [NTSC Video Timing](https://www.nesdev.org/wiki/NTSC_video)
