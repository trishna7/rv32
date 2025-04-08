`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] uio_in;
  wire [7:0] uio_oe;  

  reg uart_rx, spi_miso;
  wire uart_tx, spi_cs, spi_sck, spi_mosi;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_trishna_test tt_um_trishna_test (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  ({uart_rx, 7'b0}),    // Dedicated inputs
      .uo_out ({7'b0, uart_tx}),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(4'b0, spi_sck, spi_miso, spi_mosi, spi_cs),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule
