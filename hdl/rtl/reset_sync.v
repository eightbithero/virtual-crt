//******************************************************
// Reset Synchronizer
// Description: Synchronizes async reset to clock domain
// Prevents metastability issues
//******************************************************

module reset_sync (
    input wire clk,           // Clock domain to sync to
    input wire async_rst_n,   // Async active-low reset input
    output reg sync_rst_n     // Synchronized active-low reset output
);

//******************************************************
// Two-stage synchronizer to prevent metastability
//******************************************************
reg rst_sync_1;
reg rst_sync_2;

always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
        rst_sync_1 <= 1'b0;
        rst_sync_2 <= 1'b0;
        sync_rst_n <= 1'b0;
    end else begin
        rst_sync_1 <= 1'b1;
        rst_sync_2 <= rst_sync_1;
        sync_rst_n <= rst_sync_2;
    end
end

endmodule
