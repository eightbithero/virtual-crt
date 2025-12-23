//******************************************************
// Timing Constraints for Virtual CRT
// Tang Nano 4K - GW1NSR-4C
//******************************************************

//******************************************************
// Clock Definitions
//******************************************************

// 27 MHz input clock from onboard oscillator
create_clock -name clk_27m -period 37.037 -waveform {0 18.518} [get_ports {clk_27m}]

// NTSC pixel clock: 3.579545 MHz (NTSC color subcarrier / chroma)
// Generated from PLL - will be defined in HDL
create_generated_clock -name clk_ntsc_pixel -source [get_ports {clk_27m}] -master_clock clk_27m -divide_by 8 -multiply_by 1 [get_nets {clk_ntsc_pixel}]

// NTSC master clock: 21.477272 MHz (6x NTSC color subcarrier)
// For NES PPU accurate timing
create_generated_clock -name clk_ntsc_master -source [get_ports {clk_27m}] -master_clock clk_27m -divide_by 1 -multiply_by 1 [get_nets {clk_ntsc_master}]

// USB clock domain (if using USB 2.0 HS: 60 MHz, FS: 12 MHz)
create_generated_clock -name clk_usb -source [get_ports {clk_27m}] -master_clock clk_27m -divide_by 1 -multiply_by 2 [get_nets {clk_usb}]

//******************************************************
// Clock Groups (asynchronous clock domains)
//******************************************************

set_clock_groups -asynchronous \
    -group [get_clocks {clk_27m}] \
    -group [get_clocks {clk_ntsc_pixel}] \
    -group [get_clocks {clk_ntsc_master}] \
    -group [get_clocks {clk_usb}]

//******************************************************
// Input Delays
//******************************************************

// USB data inputs
set_input_delay -clock clk_usb -max 5.0 [get_ports {usb_dp usb_dm}]
set_input_delay -clock clk_usb -min 1.0 [get_ports {usb_dp usb_dm}]

// Reset button
set_input_delay -clock clk_27m -max 10.0 [get_ports {rst_n}]

//******************************************************
// Output Delays
//******************************************************

// NTSC outputs - critical timing for video DAC
set_output_delay -clock clk_ntsc_pixel -max 5.0 [get_ports {ntsc_luma[*] ntsc_chroma[*] ntsc_sync}]
set_output_delay -clock clk_ntsc_pixel -min -1.0 [get_ports {ntsc_luma[*] ntsc_chroma[*] ntsc_sync}]

// Debug outputs
set_output_delay -clock clk_27m -max 10.0 [get_ports {led[*]}]

//******************************************************
// False Paths
//******************************************************

// Asynchronous reset
set_false_path -from [get_ports {rst_n}]

// LED outputs (not timing critical)
set_false_path -to [get_ports {led[*]}]

//******************************************************
// Multi-cycle Paths
//******************************************************

// Add multi-cycle paths if needed for specific paths
# set_multicycle_path -from [get_clocks {clk_source}] -to [get_clocks {clk_dest}] -setup 2
# set_multicycle_path -from [get_clocks {clk_source}] -to [get_clocks {clk_dest}] -hold 1
