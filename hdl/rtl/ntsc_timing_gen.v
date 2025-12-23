//******************************************************
// NTSC Timing Generator
// Description: Generates NTSC-compliant sync signals
//
// NTSC Standards (525-line, 60 Hz):
// - Total lines: 525
// - Active lines: 486
// - Field rate: 59.94 Hz
// - Line rate: 15.734 kHz
// - Horizontal timing:
//   - Total: 63.556 μs
//   - Sync: 4.7 μs
//   - Back porch: 5.7 μs
//   - Active: 52.656 μs
//******************************************************

module ntsc_timing_gen (
    input wire clk_pixel,        // NTSC pixel clock (~3.58 MHz)
    input wire clk_master,       // NTSC master clock (~21.48 MHz)
    input wire rst_n,

    input wire hsync_in,         // Input H-sync (from source)
    input wire vsync_in,         // Input V-sync (from source)

    output reg hsync_out,        // NTSC H-sync
    output reg vsync_out,        // NTSC V-sync
    output reg sync_out          // Composite sync (H+V)
);

//******************************************************
// NTSC Timing Constants
// Based on NTSC color subcarrier frequency
//******************************************************

// Horizontal timing (in pixel clocks @ 3.58 MHz)
localparam H_TOTAL = 228;        // Total pixels per line
localparam H_SYNC_START = 0;
localparam H_SYNC_END = 17;      // ~4.7 μs sync pulse
localparam H_BACK_PORCH = 37;    // Back porch end
localparam H_ACTIVE_START = 37;
localparam H_ACTIVE_END = 225;   // Active video region

// Vertical timing (in lines)
localparam V_TOTAL = 525;        // Total lines per frame
localparam V_SYNC_START = 0;
localparam V_SYNC_END = 3;       // Vertical sync pulse (3 lines)
localparam V_BACK_PORCH = 20;    // Back porch end
localparam V_ACTIVE_START = 20;
localparam V_ACTIVE_END = 506;   // 486 active lines

//******************************************************
// Counters
//******************************************************
reg [7:0] h_count;    // Horizontal pixel counter
reg [9:0] v_count;    // Vertical line counter

//******************************************************
// Horizontal counter
//******************************************************
always @(posedge clk_pixel or negedge rst_n) begin
    if (!rst_n) begin
        h_count <= 8'd0;
    end else begin
        if (h_count >= H_TOTAL - 1) begin
            h_count <= 8'd0;
        end else begin
            h_count <= h_count + 8'd1;
        end
    end
end

//******************************************************
// Vertical counter
//******************************************************
always @(posedge clk_pixel or negedge rst_n) begin
    if (!rst_n) begin
        v_count <= 10'd0;
    end else begin
        if (h_count == H_TOTAL - 1) begin
            if (v_count >= V_TOTAL - 1) begin
                v_count <= 10'd0;
            end else begin
                v_count <= v_count + 10'd1;
            end
        end
    end
end

//******************************************************
// Sync signal generation
//******************************************************
always @(posedge clk_pixel or negedge rst_n) begin
    if (!rst_n) begin
        hsync_out <= 1'b0;
        vsync_out <= 1'b0;
        sync_out <= 1'b0;
    end else begin
        // Horizontal sync (active low)
        hsync_out <= (h_count >= H_SYNC_START) && (h_count < H_SYNC_END);

        // Vertical sync (active low)
        vsync_out <= (v_count >= V_SYNC_START) && (v_count < V_SYNC_END);

        // Composite sync (active low)
        sync_out <= hsync_out | vsync_out;
    end
end

endmodule
