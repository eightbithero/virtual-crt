//******************************************************
// Clock Manager Module
// Description: Generates all required clocks using Gowin PLL
//******************************************************

module clock_manager (
    input wire clk_in,              // 27 MHz input clock
    input wire rst_n,               // Async reset

    output wire clk_ntsc_pixel,     // NTSC pixel clock (~3.58 MHz)
    output wire clk_ntsc_master,    // NTSC master clock (~21.48 MHz)
    output wire clk_usb,            // USB clock (48 MHz)
    output wire pll_locked          // PLL lock status
);

//******************************************************
// Clock Frequencies:
// Input:  27.000000 MHz (onboard oscillator)
//
// NTSC:
// - Color subcarrier: 3.579545 MHz (exact NTSC spec)
// - Master clock: 21.477272 MHz (6x subcarrier, for NES PPU)
// - Pixel clock: 3.579545 MHz (subcarrier frequency)
//
// USB:
// - 48 MHz (USB Full Speed)
//
// PLL Configuration (approximate):
// CLKIN = 27 MHz
// For NTSC: FBDIV/IDIV * CLKIN / ODIV = target
// For USB: 48 MHz = 27 * 16 / 9 = 48 MHz
//******************************************************

//******************************************************
// PLL Instance (Gowin PLL IP)
// This is a placeholder - actual PLL should be generated
// using Gowin IP Core Generator in the IDE
//
// To generate PLL:
// 1. Open Gowin IDE
// 2. IP Core Generator -> PLL
// 3. Configure:
//    - Input: 27 MHz
//    - Output 1: 21.477272 MHz (NTSC master)
//    - Output 2: 48 MHz (USB)
//    - Output 3: 3.579545 MHz (NTSC pixel)
// 4. Save to hdl/ip/pll.v
//******************************************************

// Temporary direct assignments for testing
// Replace with actual PLL instance
reg [3:0] div_counter;
reg clk_div_8;

always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        div_counter <= 4'd0;
        clk_div_8 <= 1'b0;
    end else begin
        div_counter <= div_counter + 4'd1;
        if (div_counter == 4'd3) begin
            clk_div_8 <= ~clk_div_8;
            div_counter <= 4'd0;
        end
    end
end

// Placeholder clock assignments
// TODO: Replace with actual PLL instance
assign clk_ntsc_master = clk_in;           // 27 MHz (placeholder)
assign clk_ntsc_pixel = clk_div_8;         // ~3.375 MHz (placeholder)
assign clk_usb = clk_in;                   // 27 MHz (placeholder)
assign pll_locked = rst_n;                 // Assume locked when reset released

//******************************************************
// Actual PLL instantiation (commented out - needs IP gen)
//******************************************************
/*
Gowin_PLL u_pll (
    .clkin(clk_in),              // 27 MHz input
    .clkout0(clk_ntsc_master),   // 21.477272 MHz
    .clkout1(clk_usb),           // 48 MHz
    .clkout2(clk_ntsc_pixel),    // 3.579545 MHz
    .lock(pll_locked)            // PLL lock signal
);
*/

endmodule
