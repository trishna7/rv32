`default_nettype none
module uart_tx (
    input clk,
    input reset,
    input [7:0] data_in,
    input tx_start,
    output reg uart_tx,
    output reg tx_busy
);
    parameter CLK_FREQ = 10_000_000;
    parameter BAUD_RATE = 9600;
    parameter CLK_PER_BIT = CLK_FREQ / BAUD_RATE;

    reg [7:0] tx_data;
    reg [12:0] clk_count;
    reg [3:0] bit_count;
    reg transmitting;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            uart_tx <= 1;
            tx_busy <= 0;
            clk_count <= 0;
            bit_count <= 0;
            transmitting <= 0;
        end
        else if (tx_start && !transmitting) begin
            tx_data <= data_in;
            transmitting <= 1;
            tx_busy <= 1;
            clk_count <= 0;
            bit_count <= 0;
            uart_tx <= 0;  // Start bit
        end
        else if (transmitting) begin
            clk_count <= clk_count + 1;
            if (clk_count == (CLK_PER_BIT / 2)) begin
                if (bit_count == 0) uart_tx <= 0;  // Start bit
                else if (bit_count <= 8) uart_tx <= tx_data[bit_count - 1];  // Data bits
                else uart_tx <= 1;  // Stop bit
                if (clk_count == (CLK_PER_BIT - 1)) begin
                    clk_count <= 0;
                    if (bit_count == 9) begin
                        transmitting <= 0;
                        tx_busy <= 0;
                    end
                    else bit_count <= bit_count + 1;
                end
            end
        end
    end
endmodule
