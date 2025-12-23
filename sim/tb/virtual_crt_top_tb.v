//******************************************************
// Virtual CRT Top Level Testbench
// Description: Basic functional test of top-level module
//******************************************************

`timescale 1ns/1ps

module virtual_crt_top_tb;

//******************************************************
// DUT signals
//******************************************************
reg clk_27m;
reg rst_n;

wire [7:0] ntsc_luma;
wire [7:0] ntsc_chroma;
wire ntsc_sync;

wire usb_dp;
wire usb_dm;

wire [5:0] led;
wire uart_tx;
reg uart_rx;

//******************************************************
// Clock generation - 27 MHz
//******************************************************
initial begin
    clk_27m = 0;
    forever #18.518 clk_27m = ~clk_27m;  // 27 MHz (period = 37.037 ns)
end

//******************************************************
// Device Under Test instantiation
//******************************************************
virtual_crt_top dut (
    .clk_27m(clk_27m),
    .rst_n(rst_n),

    .ntsc_luma(ntsc_luma),
    .ntsc_chroma(ntsc_chroma),
    .ntsc_sync(ntsc_sync),

    .usb_dp(usb_dp),
    .usb_dm(usb_dm),

    .led(led),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx)
);

//******************************************************
// Test stimulus
//******************************************************
initial begin
    // Initialize signals
    rst_n = 0;
    uart_rx = 1'b1;

    // Create VCD dump for waveform viewing
    $dumpfile("sim/waves/virtual_crt_top.vcd");
    $dumpvars(0, virtual_crt_top_tb);

    $display("=== Virtual CRT Top Level Test ===");
    $display("Starting simulation at time %0t", $time);

    // Hold reset for 1 us
    #1000;
    $display("[%0t] Releasing reset", $time);
    rst_n = 1;

    // Wait for PLL to lock (simulated by checking LED[1])
    wait(led[1] == 1'b1);
    $display("[%0t] PLL locked (LED[1]=1)", $time);

    // Monitor heartbeat LED
    $display("[%0t] Waiting for heartbeat LED...", $time);

    // Run simulation for several video frames
    // At ~60 Hz, one frame = ~16.67 ms
    #20_000_000;  // 20 ms

    $display("[%0t] Heartbeat LED state: %b", $time, led[0]);
    $display("[%0t] LED status: %b", $time, led);

    // Check NTSC outputs are active
    if (ntsc_luma !== 8'bxxxxxxxx && ntsc_chroma !== 8'bxxxxxxxx) begin
        $display("[%0t] NTSC outputs active", $time);
        $display("  Luma: %d, Chroma: %d, Sync: %b",
                 ntsc_luma, ntsc_chroma, ntsc_sync);
    end else begin
        $display("[%0t] WARNING: NTSC outputs not active", $time);
    end

    $display("=== Test Complete ===");
    $finish;
end

//******************************************************
// Monitor critical signals
//******************************************************
initial begin
    // Monitor for first 50 us in detail
    #50000;
    //$monitor("Time=%0t LED=%b NTSC_Y=%d NTSC_C=%d SYNC=%b",
    //         $time, led, ntsc_luma, ntsc_chroma, ntsc_sync);
end

//******************************************************
// Timeout watchdog
//******************************************************
initial begin
    #100_000_000;  // 100 ms timeout
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule
