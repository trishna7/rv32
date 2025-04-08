`default_nettype none
module Registers (
    input clk,
    input reset,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input write_enable,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] reg_file [0:31];

    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) reg_file[i] <= 32'b0;
        end
        else if (write_enable && rd != 0) begin
            reg_file[rd] <= write_data;
        end
    end

    assign read_data1 = (rs1 == 0) ? 32'b0 : reg_file[rs1];
    assign read_data2 = (rs2 == 0) ? 32'b0 : reg_file[rs2];
endmodule
