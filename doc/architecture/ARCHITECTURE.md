# Virtual CRT - System Architecture

## Overview

Virtual CRT is an FPGA-based system that converts digital video input (via USB-C) to NTSC composite video for display on CRT televisions. The system emulates NES (2C02 PPU) video artifacts to achieve authentic retro aesthetics.

## Platform

- **FPGA:** Gowin GW1NSR-4C (Tang Nano 4K)
- **CRT Display:** Sharp 21F-PT220
- **Video Standard:** NTSC (525-line, 59.94 Hz)

## System Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Tang Nano 4K                          │
│                                                               │
│  ┌──────────┐                                                │
│  │ 27 MHz   │──────┐                                         │
│  │Oscillator│      │                                         │
│  └──────────┘      │                                         │
│                    │                                         │
│              ┌─────▼──────┐                                  │
│              │   Clock    │                                  │
│              │ Management │                                  │
│              │    (PLL)   │                                  │
│              └─────┬──────┘                                  │
│                    │                                         │
│         ┌──────────┼─────────────┐                           │
│         │          │             │                           │
│    ┌────▼───┐ ┌───▼────┐   ┌───▼────┐                       │
│    │ USB    │ │ NTSC   │   │ NTSC   │                       │
│    │ Clock  │ │ Master │   │ Pixel  │                       │
│    │48 MHz  │ │21.5MHz │   │3.58MHz │                       │
│    └────┬───┘ └────┬───┘   └───┬────┘                       │
│         │          │           │                             │
│  ┌──────▼─────┐    │           │                             │
│  │    USB     │    │           │                             │
│  │   Video    │    │           │                             │
│  │ Interface  │    │           │                             │
│  │(Test Gen)  │    │           │                             │
│  └──────┬─────┘    │           │                             │
│         │          │           │                             │
│    ┌────▼──────────▼───────────▼─────┐                       │
│    │    NTSC Video Generator          │                      │
│    │                                  │                      │
│    │  ┌────────────┐  ┌────────────┐ │                      │
│    │  │ RGB → YIQ  │  │   Timing   │ │                      │
│    │  │ Converter  │  │  Generator │ │                      │
│    │  └─────┬──────┘  └──────┬─────┘ │                      │
│    │        │                │       │                      │
│    │  ┌─────▼────────────────▼─────┐ │                      │
│    │  │    Chroma Modulator        │ │                      │
│    │  │  (I/Q → Subcarrier)        │ │                      │
│    │  └───────────┬────────────────┘ │                      │
│    └──────────────┼──────────────────┘                       │
│                   │                                          │
│              ┌────▼────┐                                     │
│              │   DAC   │                                     │
│              │ Outputs │                                     │
│              └────┬────┘                                     │
└───────────────────┼──────────────────────────────────────────┘
                    │
              ┌─────▼─────┐
              │ CRT       │
              │ Display   │
              └───────────┘
```

## Clock Domains

### Primary Clocks

1. **System Clock (27 MHz)**
   - Source: Onboard oscillator
   - Purpose: Input to PLL, general system logic

2. **NTSC Master Clock (21.477272 MHz)**
   - Derived from PLL
   - Frequency: 6× NTSC color subcarrier
   - Purpose: High-precision chroma modulation, NES PPU accurate timing

3. **NTSC Pixel Clock (3.579545 MHz)**
   - Derived from PLL
   - Frequency: NTSC color subcarrier frequency
   - Purpose: Pixel-rate video processing

4. **USB Clock (48 MHz)**
   - Derived from PLL
   - Purpose: USB Full Speed (USB 2.0 FS)

### Clock Domain Crossings

All clock domains are asynchronous and properly synchronized using:
- Dual-flip-flop synchronizers for single-bit signals
- Async FIFOs for multi-bit data transfers

## Module Hierarchy

### Top Level (`virtual_crt_top.v`)

Integrates all subsystems:
- Clock management
- Reset synchronization
- USB video interface
- NTSC video generator
- Debug interfaces

### Clock Management (`clock_manager.v`)

Generates all required clocks using Gowin PLL IP.

**TODO:** PLL must be configured in Gowin IDE:
- Input: 27 MHz
- Output 1: 21.477272 MHz (NTSC master)
- Output 2: 48 MHz (USB)
- Output 3: 3.579545 MHz (NTSC pixel)

### USB Video Interface (`usb_video_interface.v`)

**Current Status:** Stub implementation with test pattern generator

**Test Pattern:** 320×240 color bars (8 colors)

**Future Implementation:**
- USB PHY interface
- USB Video Class (UVC) protocol stack
- Frame buffer management
- Color space conversion

### NTSC Video Generator (`ntsc_video_generator.v`)

Main NTSC signal generation pipeline:

1. **RGB to YIQ Conversion** (`rgb_to_yiq.v`)
   - Matrix multiplication with fixed-point arithmetic
   - Pipeline depth: 3 stages
   - YIQ coefficients per NTSC standard

2. **Timing Generator** (`ntsc_timing_gen.v`)
   - NTSC-compliant sync signals
   - 525 lines, 59.94 Hz field rate
   - Horizontal: 15.734 kHz line rate

3. **Chroma Modulator** (`chroma_modulator.v`)
   - Quadrature modulation: C(t) = I·cos(ωt) + Q·sin(ωt)
   - 6-sample sin/cos LUT
   - Phase reset on H-sync for color burst alignment

## Video Signal Path

```
Input RGB → YIQ Conversion → Chroma Modulation → DAC Output
    ↓                              ↓
Timing Gen → Sync Signals ─────────┘
```

## DAC Implementation

NTSC output uses resistor-ladder DACs:
- **Luma:** 8-bit R-2R ladder
- **Chroma:** 8-bit R-2R ladder
- **Sync:** Digital output

## Memory Map

Currently no memory-mapped registers.

Future additions:
- Control registers (generator selection, debug)
- Frame buffer (for USB video)
- Color palette RAM (for NES mode)

## NTSC Generator Modes

Parameter `GENERATOR_TYPE` in `ntsc_video_generator.v`:

- **Mode 0:** Basic NTSC generator (current)
- **Mode 1:** NES PPU (2C02) accurate timing (TODO)
- **Mode 2:** Custom with enhanced artifacts (TODO)

## Reset Strategy

- **Async Reset Input:** `rst_n` (active-low button)
- **PLL Lock:** Must be asserted before releasing system reset
- **Per-Domain Reset:** Each clock domain has synchronized reset
- **Reset Sequence:**
  1. Assert `rst_n`
  2. Wait for PLL lock
  3. Release synchronized resets per domain

## Debug Features

- **LEDs:**
  - LED[0]: Heartbeat (~1.6 Hz)
  - LED[1]: PLL lock status
  - LED[2]: NTSC reset status
  - LED[3]: USB reset status
  - LED[4]: Video H-sync indicator
  - LED[5]: Video V-sync indicator

- **UART:** Reserved for future debug console

## Performance Targets

- **Video Latency:** < 1 frame (< 16.7 ms)
- **Clock Accuracy:** ±0.01% for NTSC timing
- **Resource Usage:** < 50% of GW1NSR-4C

## Future Enhancements

1. **USB Video Implementation**
   - Full UVC stack
   - DisplayPort Alt Mode support
   - Multiple resolution support

2. **NES PPU Emulation**
   - Cycle-accurate 2C02 timing
   - PPU artifacts (dot crawl, rainbow banding)
   - Color emphasis bits

3. **Advanced Features**
   - On-screen display (OSD)
   - Picture controls (brightness, contrast, hue)
   - Multiple aspect ratios
   - Scanline effects

## References

- [NTSC Video Standard](https://www.nesdev.org/wiki/NTSC_video)
- [NES 2C02 PPU](https://www.nesdev.org/wiki/PPU)
- [Tang Nano 4K Documentation](http://www.gowinsemi.com.cn/)
