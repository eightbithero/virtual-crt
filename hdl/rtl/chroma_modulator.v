//******************************************************
// Chroma Modulator
// Description: Modulates I/Q components onto NTSC color subcarrier
//
// NTSC Chroma:
// C(t) = I * cos(ωt) + Q * sin(ωt)
// where ω = 2π * 3.579545 MHz (color subcarrier)
//
// Uses lookup tables for sin/cos generation
//******************************************************

module chroma_modulator (
    input wire clk_pixel,        // NTSC pixel clock (~3.58 MHz)
    input wire clk_master,       // NTSC master clock (~21.48 MHz)
    input wire rst_n,

    input wire [7:0] i,          // I component (signed, offset by 128)
    input wire [7:0] q,          // Q component (signed, offset by 128)
    input wire hsync,            // H-sync for phase reset

    output reg [7:0] chroma_out  // Modulated chroma output
);

//******************************************************
// Subcarrier phase counter
// At master clock (~21.48 MHz), which is 6x subcarrier
// Phase increments 0-5 for one complete cycle
//******************************************************
reg [2:0] phase;
reg [7:0] sin_val;
reg [7:0] cos_val;

//******************************************************
// Phase counter - resets on H-sync for proper color burst
//******************************************************
always @(posedge clk_master or negedge rst_n) begin
    if (!rst_n) begin
        phase <= 3'd0;
    end else begin
        if (hsync) begin
            phase <= 3'd0;  // Reset phase at beginning of line
        end else begin
            if (phase >= 3'd5) begin
                phase <= 3'd0;
            end else begin
                phase <= phase + 3'd1;
            end
        end
    end
end

//******************************************************
// Sine/Cosine lookup table
// 6 samples per cycle, values scaled to [-127, 127]
//******************************************************
always @(*) begin
    case (phase)
        3'd0: begin
            cos_val = 8'd127;  // cos(0°) = 1.0
            sin_val = 8'd0;    // sin(0°) = 0.0
        end
        3'd1: begin
            cos_val = 8'd64;   // cos(60°) = 0.5
            sin_val = 8'd110;  // sin(60°) = 0.866
        end
        3'd2: begin
            cos_val = -8'd64;  // cos(120°) = -0.5
            sin_val = 8'd110;  // sin(120°) = 0.866
        end
        3'd3: begin
            cos_val = -8'd127; // cos(180°) = -1.0
            sin_val = 8'd0;    // sin(180°) = 0.0
        end
        3'd4: begin
            cos_val = -8'd64;  // cos(240°) = -0.5
            sin_val = -8'd110; // sin(240°) = -0.866
        end
        3'd5: begin
            cos_val = 8'd64;   // cos(300°) = 0.5
            sin_val = -8'd110; // sin(300°) = -0.866
        end
        default: begin
            cos_val = 8'd0;
            sin_val = 8'd0;
        end
    endcase
end

//******************************************************
// Modulation calculation
// C = I * cos(ωt) + Q * sin(ωt)
// Note: I and Q are offset by 128, so subtract 128 first
//******************************************************
reg signed [15:0] i_signed;
reg signed [15:0] q_signed;
reg signed [23:0] i_cos;
reg signed [23:0] q_sin;
reg signed [23:0] chroma_sum;

always @(posedge clk_master or negedge rst_n) begin
    if (!rst_n) begin
        i_signed <= 16'd0;
        q_signed <= 16'd0;
        i_cos <= 24'd0;
        q_sin <= 24'd0;
        chroma_sum <= 24'd0;
        chroma_out <= 8'd128; // Mid-level
    end else begin
        // Convert I and Q to signed (remove 128 offset)
        i_signed <= $signed(i) - 16'sd128;
        q_signed <= $signed(q) - 16'sd128;

        // Multiply by carrier
        i_cos <= i_signed * $signed(cos_val);
        q_sin <= q_signed * $signed(sin_val);

        // Sum components
        chroma_sum <= i_cos + q_sin;

        // Scale back and add offset
        // Divide by 127 to normalize, then add 128 for unsigned output
        if (chroma_sum[23:7] > 17'sd127)
            chroma_out <= 8'd255;
        else if (chroma_sum[23:7] < -17'sd128)
            chroma_out <= 8'd0;
        else
            chroma_out <= chroma_sum[14:7] + 8'd128;
    end
end

endmodule
