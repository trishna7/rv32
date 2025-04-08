`default_nettype none
module PC (
    input wire clk,
    input wire reset,
    input wire exec_enable,
    input wire pc_src,
    input wire [31:0] pc_next,
    input wire [31:0] pc_target,
    input wire [31:0] pcplus4,
    output reg [31:0] pc
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'b0;
        else if (exec_enable)
            pc <= pc_next;
    end
endmodule
