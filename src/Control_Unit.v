`default_nettype none
module Control_unit (
    input [6:0] opcode,
    input zero,
    output reg pc_src,
    output reg reg_write,
    output reg [2:0] imm_src,
    output reg alu_src,
    output reg mem_write,
    output reg [1:0] result_src,
    output reg branch,
    output reg [1:0] alu_op,
    output reg jump,
    output reg jal_src,
    output reg u_src,
    output reg mem_read
);
    always @(*) begin
        {pc_src, reg_write, imm_src, alu_src, mem_write, result_src, branch, alu_op, jump, jal_src, u_src, mem_read} = 14'b0;
        case (opcode)
            7'b0110011: begin  // R-type
                reg_write = 1;
                alu_op = 2'b10;
            end
            7'b0010011: begin  // I-type (ALU)
                reg_write = 1;
                imm_src = 3'b000;
                alu_src = 1;
                alu_op = 2'b10;
            end
            7'b0000011: begin  // I-type (load)
                reg_write = 1;
                imm_src = 3'b000;
                alu_src = 1;
                alu_op = 2'b00;
                result_src = 2'b01;  // SPI data
                mem_read = 1;
            end
            7'b0100011: begin  // S-type (store)
                imm_src = 3'b001;
                alu_src = 1;
                alu_op = 2'b00;
                mem_write = 1;
            end
            7'b1100011: begin  // B-type
                imm_src = 3'b011;
                branch = 1;
                alu_op = 2'b01;
                pc_src = zero;
            end
            7'b1101111: begin  // JAL
                imm_src = 3'b100;
                reg_write = 1;
                result_src = 2'b10;
                jump = 1;
                jal_src = 0;
            end
            7'b1100111: begin  // JALR
                imm_src = 3'b000;
                reg_write = 1;
                result_src = 2'b10;
                jump = 1;
                jal_src = 1;
            end
            7'b0110111: begin  // LUI
                reg_write = 1;
                imm_src = 3'b010;
                result_src = 2'b11;
                u_src = 0;
            end
            7'b0010111: begin  // AUIPC
                reg_write = 1;
                imm_src = 3'b010;
                result_src = 2'b11;
                u_src = 1;
            end
        endcase
    end
endmodule
