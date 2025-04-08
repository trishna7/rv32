`default_nettype none
module alu_decoder (
    input opcode_bit5,
    input [2:0] funct3,
    input funct7_bit5,
    input [1:0] alu_op,
    output reg [3:0] alu_control
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_control = 4'b0010;  // Add for lw/sw
            2'b01: alu_control = 4'b0110;  // Subtract for beq
            2'b10: begin
                case ({funct7_bit5, funct3})
                    4'b0000: alu_control = 4'b0010;  // ADD
                    4'b1000: alu_control = 4'b0110;  // SUB
                    4'b0001: alu_control = 4'b0011;  // SLL
                    4'b0010: alu_control = 4'b0100;  // SLT
                    4'b0100: alu_control = 4'b0101;  // XOR
                    4'b0110: alu_control = 4'b0001;  // OR
                    4'b0111: alu_control = 4'b0000;  // AND
                    default: alu_control = 4'b0000;
                endcase
            end
            default: alu_control = 4'b0000;
        endcase
    end
endmodule
