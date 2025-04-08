`default_nettype none

module immediate (
    input wire [31:7] instruction,
    input wire [2:0] imm_src,
    output reg [31:0] imm_ext
);

always @(*) begin
    case (imm_src)
        3'b000 : imm_ext = {{20{instruction[31]}}, instruction[31:20]}; //i type, making it 32 bit with addition of 20 bits of signed bit to 12 bit
        3'b001 : imm_ext = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // s-type
        3'b010 : imm_ext = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // b type
        3'b011 : imm_ext = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // j type
        3'b100 : imm_ext = {{instruction[31]}, instruction[31:12], 12'b0}; // u type
        default : imm_ext = 32'b0;
    endcase
end
endmodule
