//-----------------------------------------------------------------------------
// Title         : Block RAM 
// Project       : general_module
//-----------------------------------------------------------------------------
// File          : bram.v
// Author        : kengo yanagihara  <kengo@sirotan>
// Created       : 28.06.2024
// Last modified : 2024/06/29
//-----------------------------------------------------------------------------
// Description :
// This module implements a simple dual-port Block RAM(BRAM).
// The BRAM supports synchronous write and read operations. It has
// separate ports for reading and writing, allowing for simultaneous
// read adn write operations in different addresses.
//
// Inputs:
//   - clk        : Clock signal.
//   - rst_n      : Active-low reset signal.
//   - bram_we    : Write enable signal. When high, data is written to the BRAM.
//   - bram_re    : Read enable signal. When high, data is read from the BRAM.
//   - bram_raddr : Read address input for the BRAM.
//   - bram_waddr : Write address input for the BRAM.
//   - bram_din   : Data input for write operations.
//
// Output:
//   - bram_dout  : Data output from the BRAM.
//
// The BRAM is parameterized with:
//   - FIFO_SIZE : The depth of the RAM, i.e., the number of entries it can store.
//   - BIT_WIDTH : The width of each data entry.
//
// The memory is initialized to zero at the start.
//
//-----------------------------------------------------------------------------
// Copyright (c) 2024 by kengo yanagihara
//------------------------------------------------------------------------------
// Modification history :
// 28.06.2024 : created
//-----------------------------------------------------------------------------

`default_nettype none

module bram #(
    parameter integer FIFO_SIZE = 1024,
    parameter integer BIT_WIDTH = 1024
) (
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       bram_we,
    input  wire                       bram_re,
    input  wire [$clog2(FIFO_SIZE):0] bram_raddr,
    input  wire [$clog2(FIFO_SIZE):0] bram_waddr,
    input  wire [      BIT_WIDTH-1:0] bram_din,
    output reg  [      BIT_WIDTH-1:0] bram_dout
);

    (* ram_style = "block" *)
    reg [BIT_WIDTH-1:0] mem[FIFO_SIZE-1:0];

    //write data
    always @(posedge clk) begin
        if (bram_we) mem[bram_waddr] <= bram_din;
    end

    //read data
    always @(posedge clk) begin
        if (!rst_n) bram_dout <= 1'd0;
        else if (bram_re) bram_dout <= mem[bram_raddr];
    end

    integer i;
    initial begin
        for (i = 0; i < FIFO_SIZE; i = i + 1) mem[i] = 'b0;
    end
endmodule

`default_nettype wire
