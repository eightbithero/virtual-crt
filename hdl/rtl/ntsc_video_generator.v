//******************************************************
// NTSC Video Generator
// Description: Main NTSC video generation module
// Supports modular architecture for different generators
//******************************************************

module ntsc_video_generator (
    input wire clk_pixel,        // NTSC pixel clock (~3.58 MHz)
    input wire clk_master,       // NTSC master clock (~21.48 MHz)
    input wire rst_n,            // Active-low reset

    // Input video (from USB or other source)
    input wire [7:0] video_r,
    input wire [7:0] video_g,
    input wire [7:0] video_b,
    input wire video_hsync,
    input wire video_vsync,
    input wire video_de,         // Data enable

    // NTSC composite output
    output wire [7:0] ntsc_luma,   // Luma (Y) channel
    output wire [7:0] ntsc_chroma, // Chroma (C) channel
    output wire ntsc_sync          // Composite sync
);

//******************************************************
// Generator selection parameter
// 0: Basic NTSC generator
// 1: NES PPU (2C02) accurate generator
// 2: Custom generator with artifacts
//******************************************************
parameter GENERATOR_TYPE = 0;

//******************************************************
// Internal signals
//******************************************************
wire [7:0] yiq_y;     // YIQ luma
wire [7:0] yiq_i;     // YIQ I component
wire [7:0] yiq_q;     // YIQ Q component

wire hsync_ntsc;      // NTSC horizontal sync
wire vsync_ntsc;      // NTSC vertical sync
wire [7:0] chroma_modulated; // Modulated chroma

//******************************************************
// RGB to YIQ Color Space Conversion
//******************************************************
rgb_to_yiq u_rgb_to_yiq (
    .clk(clk_pixel),
    .rst_n(rst_n),

    .r(video_r),
    .g(video_g),
    .b(video_b),

    .y(yiq_y),
    .i(yiq_i),
    .q(yiq_q)
);

//******************************************************
// NTSC Timing Generator
// Generates proper NTSC sync signals
//******************************************************
ntsc_timing_gen u_timing_gen (
    .clk_pixel(clk_pixel),
    .clk_master(clk_master),
    .rst_n(rst_n),

    .hsync_in(video_hsync),
    .vsync_in(video_vsync),

    .hsync_out(hsync_ntsc),
    .vsync_out(vsync_ntsc),
    .sync_out(ntsc_sync)
);

//******************************************************
// Chroma Modulator
// Modulates I/Q onto color subcarrier
//******************************************************
chroma_modulator u_chroma_mod (
    .clk_pixel(clk_pixel),
    .clk_master(clk_master),
    .rst_n(rst_n),

    .i(yiq_i),
    .q(yiq_q),
    .hsync(hsync_ntsc),

    .chroma_out(chroma_modulated)
);

//******************************************************
// Output Assignment
//******************************************************
assign ntsc_luma = yiq_y;
assign ntsc_chroma = chroma_modulated;

endmodule
