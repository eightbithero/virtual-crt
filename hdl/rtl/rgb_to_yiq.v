//******************************************************
// RGB to YIQ Color Space Converter
// Description: Converts RGB to NTSC YIQ color space
//
// YIQ conversion matrix (NTSC standard):
// Y = 0.299*R + 0.587*G + 0.114*B
// I = 0.596*R - 0.275*G - 0.321*B
// Q = 0.212*R - 0.523*G + 0.311*B
//
// Fixed-point implementation: 8.8 format
//******************************************************

module rgb_to_yiq (
    input wire clk,
    input wire rst_n,

    input wire [7:0] r,
    input wire [7:0] g,
    input wire [7:0] b,

    output reg [7:0] y,
    output reg [7:0] i,
    output reg [7:0] q
);

//******************************************************
// Fixed-point coefficients (8.8 format)
// Multiply by 256 to get integer representation
//******************************************************

// Y coefficients
localparam signed [15:0] Y_R = 16'sd77;   // 0.299 * 256 ≈ 77
localparam signed [15:0] Y_G = 16'sd150;  // 0.587 * 256 ≈ 150
localparam signed [15:0] Y_B = 16'sd29;   // 0.114 * 256 ≈ 29

// I coefficients
localparam signed [15:0] I_R = 16'sd153;  // 0.596 * 256 ≈ 153
localparam signed [15:0] I_G = -16'sd70;  // -0.275 * 256 ≈ -70
localparam signed [15:0] I_B = -16'sd82;  // -0.321 * 256 ≈ -82

// Q coefficients
localparam signed [15:0] Q_R = 16'sd54;   // 0.212 * 256 ≈ 54
localparam signed [15:0] Q_G = -16'sd134; // -0.523 * 256 ≈ -134
localparam signed [15:0] Q_B = 16'sd80;   // 0.311 * 256 ≈ 80

//******************************************************
// Intermediate calculation signals
//******************************************************
reg signed [23:0] y_calc;
reg signed [23:0] i_calc;
reg signed [23:0] q_calc;

reg signed [15:0] r_ext;
reg signed [15:0] g_ext;
reg signed [15:0] b_ext;

//******************************************************
// Pipeline stage 1: Extend inputs
//******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_ext <= 16'd0;
        g_ext <= 16'd0;
        b_ext <= 16'd0;
    end else begin
        r_ext <= {8'd0, r};
        g_ext <= {8'd0, g};
        b_ext <= {8'd0, b};
    end
end

//******************************************************
// Pipeline stage 2: Multiply and accumulate
//******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        y_calc <= 24'd0;
        i_calc <= 24'd0;
        q_calc <= 24'd0;
    end else begin
        // Y = 0.299*R + 0.587*G + 0.114*B
        y_calc <= (Y_R * r_ext) + (Y_G * g_ext) + (Y_B * b_ext);

        // I = 0.596*R - 0.275*G - 0.321*B
        i_calc <= (I_R * r_ext) + (I_G * g_ext) + (I_B * b_ext);

        // Q = 0.212*R - 0.523*G + 0.311*B
        q_calc <= (Q_R * r_ext) + (Q_G * g_ext) + (Q_B * b_ext);
    end
end

//******************************************************
// Pipeline stage 3: Divide by 256 and clamp
//******************************************************
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        y <= 8'd0;
        i <= 8'd0;
        q <= 8'd0;
    end else begin
        // Divide by 256 (shift right 8 bits) and clamp to 8-bit
        // Y is always positive
        if (y_calc[23:8] > 16'd255)
            y <= 8'd255;
        else if (y_calc[23])
            y <= 8'd0;
        else
            y <= y_calc[15:8];

        // I and Q can be negative, add 128 offset for unsigned output
        // Clamp to [0, 255] range
        if (i_calc[23:8] > 16'sd127)
            i <= 8'd255;
        else if (i_calc[23:8] < -16'sd128)
            i <= 8'd0;
        else
            i <= i_calc[15:8] + 8'd128;

        if (q_calc[23:8] > 16'sd127)
            q <= 8'd255;
        else if (q_calc[23:8] < -16'sd128)
            q <= 8'd0;
        else
            q <= q_calc[15:8] + 8'd128;
    end
end

endmodule
