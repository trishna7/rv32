`default_nettype none

module Data_Memory (
    input clk,
    input reset,
    input mem_write, //write enable to memory
    //input mem_read, // read enable from memory
    input [31:0] address, //specify memory location
    input [31:0] write_data,
    output [31:0] read_data
);
    reg [31:0] mem [0:255];

    always @(posedge clk) begin
        if (mem_write) 
            mem [address[31:2]] <= write_data; //write to memory
    end

    assign read_data = mem[address[31:2]];
endmodule
