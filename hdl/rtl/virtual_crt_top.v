//******************************************************
// Virtual CRT Top Level Module
// Platform: Tang Nano 4K (GW1NSR-4C)
// Description: Main top-level module integrating all subsystems
//******************************************************

module virtual_crt_top (
    // Clock and Reset
    input wire clk_27m,           // 27 MHz onboard oscillator
    input wire rst_n,             // Active-low reset button

    // NTSC Video Output
    output wire [7:0] ntsc_luma,   // Luma (Y) channel - 8-bit DAC
    output wire [7:0] ntsc_chroma, // Chroma (C) channel - 8-bit DAC
    output wire ntsc_sync,         // Composite sync signal

    // USB-C Interface
    inout wire usb_dp,            // USB D+
    inout wire usb_dm,            // USB D-

    // Debug Interface
    output wire [5:0] led,        // Debug LEDs
    output wire uart_tx,          // Debug UART TX
    input wire uart_rx            // Debug UART RX
);

//******************************************************
// Internal Clocks
//******************************************************
wire clk_ntsc_pixel;    // NTSC pixel clock (~3.58 MHz)
wire clk_ntsc_master;   // NTSC master clock (~21.48 MHz)
wire clk_usb;           // USB clock (48/60 MHz)
wire pll_locked;        // PLL lock indicator

//******************************************************
// Reset Synchronization
//******************************************************
wire sys_rst_n;         // System reset (synchronized)
wire ntsc_rst_n;        // NTSC domain reset
wire usb_rst_n;         // USB domain reset

//******************************************************
// Video Pipeline Signals
//******************************************************
wire [7:0] video_r;     // Input video Red
wire [7:0] video_g;     // Input video Green
wire [7:0] video_b;     // Input video Blue
wire video_hsync;       // Input video H-sync
wire video_vsync;       // Input video V-sync
wire video_de;          // Input video data enable

wire [7:0] ntsc_y;      // NTSC Y (luma)
wire [7:0] ntsc_i;      // NTSC I (in-phase chroma)
wire [7:0] ntsc_q;      // NTSC Q (quadrature chroma)

//******************************************************
// Debug Signals
//******************************************************
reg [23:0] heartbeat_counter;
wire heartbeat;

//******************************************************
// Clock Management Unit
//******************************************************
clock_manager u_clock_manager (
    .clk_in(clk_27m),
    .rst_n(rst_n),

    .clk_ntsc_pixel(clk_ntsc_pixel),
    .clk_ntsc_master(clk_ntsc_master),
    .clk_usb(clk_usb),
    .pll_locked(pll_locked)
);

//******************************************************
// Reset Synchronizers
//******************************************************
reset_sync u_reset_sync_sys (
    .clk(clk_27m),
    .async_rst_n(rst_n & pll_locked),
    .sync_rst_n(sys_rst_n)
);

reset_sync u_reset_sync_ntsc (
    .clk(clk_ntsc_master),
    .async_rst_n(rst_n & pll_locked),
    .sync_rst_n(ntsc_rst_n)
);

reset_sync u_reset_sync_usb (
    .clk(clk_usb),
    .async_rst_n(rst_n & pll_locked),
    .sync_rst_n(usb_rst_n)
);

//******************************************************
// USB Video Input Interface
// TODO: Implement USB video receiver
//******************************************************
usb_video_interface u_usb_video (
    .clk(clk_usb),
    .rst_n(usb_rst_n),

    .usb_dp(usb_dp),
    .usb_dm(usb_dm),

    .video_r(video_r),
    .video_g(video_g),
    .video_b(video_b),
    .video_hsync(video_hsync),
    .video_vsync(video_vsync),
    .video_de(video_de)
);

//******************************************************
// NTSC Video Generator
// Modular architecture - can switch between generators
//******************************************************
ntsc_video_generator u_ntsc_gen (
    .clk_pixel(clk_ntsc_pixel),
    .clk_master(clk_ntsc_master),
    .rst_n(ntsc_rst_n),

    // Input video
    .video_r(video_r),
    .video_g(video_g),
    .video_b(video_b),
    .video_hsync(video_hsync),
    .video_vsync(video_vsync),
    .video_de(video_de),

    // NTSC output
    .ntsc_luma(ntsc_luma),
    .ntsc_chroma(ntsc_chroma),
    .ntsc_sync(ntsc_sync)
);

//******************************************************
// Debug Heartbeat LED
//******************************************************
always @(posedge clk_27m or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        heartbeat_counter <= 24'd0;
    end else begin
        heartbeat_counter <= heartbeat_counter + 24'd1;
    end
end

assign heartbeat = heartbeat_counter[23]; // ~1.6 Hz blink

//******************************************************
// Debug LED Assignment
//******************************************************
assign led[0] = heartbeat;          // Heartbeat
assign led[1] = pll_locked;         // PLL lock status
assign led[2] = ntsc_rst_n;         // NTSC reset status
assign led[3] = usb_rst_n;          // USB reset status
assign led[4] = video_hsync;        // Video H-sync indicator
assign led[5] = video_vsync;        // Video V-sync indicator

//******************************************************
// Debug UART (placeholder)
//******************************************************
assign uart_tx = 1'b1; // Idle high

endmodule
