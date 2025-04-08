`default_nettype none
module Instruction_Memory (
    input clk,
    input reset,
    input prog_mode,
    input [2:0] prog_addr,
    input [31:0] prog_data,
    input prog_write,
    input [31:0] read_address,
    output reg [31:0] instruction_out
);
    reg [31:0] ram [0:7];

    reg [31:0] rom_out;
    always @(*) begin
        case (read_address[5:2])
            4'd0: rom_out = 32'h00000093;  // ADDI x1, x0, 0
            4'd1: rom_out = 32'h00800113;  // ADDI x2, x0, 8
            4'd2: rom_out = 32'h0000006F;  // JAL x0, 8 (jump to RAM at PC=8)
            default: rom_out = 32'h00000013;  // NOP
        endcase
    end

    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) ram[i] <= 32'b0;
        end
        else if (prog_mode && prog_write) begin
            ram[prog_addr] <= prog_data;
        end
    end

    always @(*) begin
        if (read_address[5:2] >= 4'd2)  // RAM starts at PC=8 (0x08)
            instruction_out = ram[read_address[4:2] - 3'd2];  // Offset to align RAM indices
        else
            instruction_out = rom_out;
    end
endmodule
