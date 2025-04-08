`default_nettype none
module ALU (
    input [31:0] srcA,
    input [31:0] srcB,
    input [31:0] imm_alu,
    input [3:0] alu_control,
    input alu_src,
    output reg [31:0] ALUResult,
    output zero
);
    wire [31:0] alu_in2 = alu_src ? imm_alu : srcB;

    always @(*) begin
        case (alu_control)
            4'b0000: ALUResult = srcA & alu_in2;  // AND
            4'b0001: ALUResult = srcA | alu_in2;  // OR
            4'b0010: ALUResult = srcA + alu_in2;  // ADD
            4'b0011: ALUResult = srcA << alu_in2[4:0];  // SLL
            4'b0100: ALUResult = (srcA < alu_in2) ? 32'b1 : 32'b0;  // SLT
            4'b0101: ALUResult = srcA ^ alu_in2;  // XOR
            4'b0110: ALUResult = srcA - alu_in2;  // SUB
            default: ALUResult = 32'b0;
        endcase
    end

    assign zero = (ALUResult == 0);
endmodule
