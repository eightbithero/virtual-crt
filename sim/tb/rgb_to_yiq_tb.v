//******************************************************
// RGB to YIQ Testbench
// Description: Tests RGB to YIQ color space conversion
//******************************************************

`timescale 1ns/1ps

module rgb_to_yiq_tb;

//******************************************************
// Clock and Reset
//******************************************************
reg clk;
reg rst_n;

//******************************************************
// DUT signals
//******************************************************
reg [7:0] r;
reg [7:0] g;
reg [7:0] b;

wire [7:0] y;
wire [7:0] i;
wire [7:0] q;

//******************************************************
// Clock generation - 27 MHz
//******************************************************
initial begin
    clk = 0;
    forever #18.518 clk = ~clk;  // 27 MHz
end

//******************************************************
// Device Under Test instantiation
//******************************************************
rgb_to_yiq dut (
    .clk(clk),
    .rst_n(rst_n),
    .r(r),
    .g(g),
    .b(b),
    .y(y),
    .i(i),
    .q(q)
);

//******************************************************
// Test stimulus
//******************************************************
integer error_count;

initial begin
    // Initialize signals
    rst_n = 0;
    r = 8'd0;
    g = 8'd0;
    b = 8'd0;
    error_count = 0;

    // Create VCD dump for waveform viewing
    $dumpfile("sim/waves/rgb_to_yiq.vcd");
    $dumpvars(0, rgb_to_yiq_tb);

    // Reset sequence
    #100;
    rst_n = 1;
    #100;

    $display("=== RGB to YIQ Conversion Test ===");
    $display("Time\tR\tG\tB\t|\tY\tI\tQ");
    $display("--------------------------------------------------");

    // Test case 1: Pure White
    @(posedge clk);
    r = 8'd255;
    g = 8'd255;
    b = 8'd255;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    // Test case 2: Pure Red
    @(posedge clk);
    r = 8'd255;
    g = 8'd0;
    b = 8'd0;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    // Test case 3: Pure Green
    @(posedge clk);
    r = 8'd0;
    g = 8'd255;
    b = 8'd0;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    // Test case 4: Pure Blue
    @(posedge clk);
    r = 8'd0;
    g = 8'd0;
    b = 8'd255;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    // Test case 5: Yellow (R+G)
    @(posedge clk);
    r = 8'd255;
    g = 8'd255;
    b = 8'd0;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    // Test case 6: Cyan (G+B)
    @(posedge clk);
    r = 8'd0;
    g = 8'd255;
    b = 8'd255;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    // Test case 7: Magenta (R+B)
    @(posedge clk);
    r = 8'd255;
    g = 8'd0;
    b = 8'd255;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    // Test case 8: Black
    @(posedge clk);
    r = 8'd0;
    g = 8'd0;
    b = 8'd0;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    // Test case 9: 50% Gray
    @(posedge clk);
    r = 8'd128;
    g = 8'd128;
    b = 8'd128;
    repeat(5) @(posedge clk);
    $display("%0t\t%d\t%d\t%d\t|\t%d\t%d\t%d", $time, r, g, b, y, i, q);

    $display("--------------------------------------------------");
    if (error_count == 0) begin
        $display("TEST PASSED - No errors detected");
    end else begin
        $display("TEST FAILED - %d errors detected", error_count);
    end

    // Run a bit longer
    #1000;

    $finish;
end

//******************************************************
// Monitor for debugging
//******************************************************
initial begin
    $monitor("Time=%0t rst_n=%b R=%d G=%d B=%d | Y=%d I=%d Q=%d",
             $time, rst_n, r, g, b, y, i, q);
end

endmodule
