`default_nettype none
module uart_rx (
    input clk,
    input reset,
    input uart_rx,
    output reg [7:0] data_out,
    output reg data_ready
);
    parameter CLK_FREQ = 10_000_000;
    parameter BAUD_RATE = 9600;
    parameter CLK_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [12:0] clk_count;
    reg [3:0] bit_count;
    reg [7:0] shift_reg;
    reg receiving;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_count <= 0;
            bit_count <= 0;
            shift_reg <= 0;
            receiving <= 0;
            data_ready <= 0;
            data_out <= 0;
        end
        else if (!receiving && !uart_rx) begin  // Start bit detected
            receiving <= 1;
            clk_count <= 0;
        end
        else if (receiving) begin
            clk_count <= clk_count + 1;
            if (clk_count == (CLK_PER_BIT / 2)) begin
                if (bit_count < 8) begin
                    shift_reg[bit_count] <= uart_rx;
                    bit_count <= bit_count + 1;
                end
                else if (bit_count == 8) begin
                    data_out <= shift_reg;
                    data_ready <= 1;
                    bit_count <= 0;
                    receiving <= 0;
                end
                clk_count <= 0;
            end
        end
        else begin
            data_ready <= 0;
        end
    end
endmodule
