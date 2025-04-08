/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_trishna_test (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  assign uio_oe = 8'b0000_0000;
  assign uio_out[7:4] = 4'b0000;
  assign uo_out[7:1] = 7'b000_0000;

  Processor Processor (
    .clk(clk),
    .reset(rst_n),
    .uart_rx(ui_in[7]),
    .uart_tx(uo_out[0]),
    .spi_cs(uio_out[0]),
    .spi_sck(uio_out[3]),
    .spi_mosi(uio_out[1]),
    .spi_miso(uio_out[2])
);



  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
