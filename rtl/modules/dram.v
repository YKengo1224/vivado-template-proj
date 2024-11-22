//-----------------------------------------------------------------------------
// Title         : Distributed RAM 
// Project       : general_module
//-----------------------------------------------------------------------------
// File          : bram.v
// Author        : kengo yanagihara  <kengo@sirotan>
// Created       : 28.06.2024
// Last modified : 2024/06/29
//-----------------------------------------------------------------------------
// Description :
// This module implements a simple dual-port Distributed RAM(DRAM).
// The DRAM supports synchronous write and asynchronous read operations.
// It has separate ports for reading and writing, allowing for simultaneous
// wirte and write operations in different addresses.
//
// Inputs:
//   - clk   : Clock signal.
//   - rst_n  : Active-low reset signal.
//   - dram_we    : Write enable signal. When high, data is written to the DRAM.
//   - dram_raddr : Read address input for the DRAM.
//   - dram_waddr : Write address input for the DRAM.
//   - dram_din  : Data input for write operations.
//
// Output:
//   - dram_dout  : Data output from the DRAM.
//
// The DRAM is parameterized with:
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

module dram #(
    parameter integer FIFO_SIZE = 1024,
    parameter integer BIT_WIDTH = 1024
) (
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       dram_we,
    input  wire [$clog2(FIFO_SIZE):0] dram_raddr,
    input  wire [$clog2(FIFO_SIZE):0] dram_waddr,
    input  wire [      BIT_WIDTH-1:0] dram_din,
    output wire [      BIT_WIDTH-1:0] dram_dout
);

    (* ram_style = "distributed" *)
    reg [BIT_WIDTH-1:0] mem[FIFO_SIZE-1:0];

    //write data
    always @(posedge clk) begin
        if (dram_we) mem[dram_waddr] <= dram_din;
    end

    //read data
    assign dram_dout = mem[dram_raddr];


    integer i;
    initial begin
        for (i = 0; i < FIFO_SIZE; i = i + 1) mem[i] = 'b0;
    end

endmodule

`default_nettype wire
