//-----------------------------------------------------------------------------
// Title         : FIFO
// Project       : general_modules
//-----------------------------------------------------------------------------
// File          : fifo.sv
// Author        : kengo yanagihara  <kengo@sirotan>
// Created       : 28.06.2024
// Last modified : 2024/06/30
//-----------------------------------------------------------------------------
// Description :
// This module implements a simple FIFO (First-In, First-Out) buffer.
// The FIFO supports synchronous write and read operations. It has
// separate ports for reading and writing, allowing for simultaneous
// read adn write operations in different addresses.
//
// Inputs:
//   - clk               : Clock signal.
//   - rst_n             : Active-low reset signal.
//   - fifo_we           : Write enable signal. When high, data is written to the FIFO.
//   - fifo_re           : Read enable signal. When high, data is read from the FIFO.
//   - fifo_din          : Data input for write operations.
//
// Outputs:
//   - fifo_dout         : Data output from the FIFO.
//   - fifo_ovalid       : Indicates valid data on the data output.
//   - fifo_empty        : Indicates if the FIFO is empty.
//   - fifo_full         : Indicates if the FIFO is full.
//   - fifo_almost_full  : Indicates if the FIFO is almost full
//   - fifo_almost_empty : Indicates if the FIFO is almost empty
//
// Parameters:
//   - FIFO_SIZE              : The depth of the FIFO, i.e., the number of entries it can store.
//   - BIT_WIDTH              : The width of each data entry.
//   - ALMOST_FULL_THRESHOLD  : default almost full threshold    
//   - ALMOST_EMPTY_THRESHOLD : default almost empty threshold
//
// The FIFO memory is initialized to zero at the start.
//
//-----------------------------------------------------------------------------
// Copyright (c) 2024 by kengo yanagihara
//------------------------------------------------------------------------------
// Modification history :
// 28.06.2024 : created
//-----------------------------------------------------------------------------


`default_nettype none

module fifo #(
    parameter int FIFO_SIZE = -1,
    parameter int BIT_WIDTH = -1,
    parameter int ALMOST_FULL_THRESHOLD = 5,
    parameter int ALMOST_EMPTY_THRESHOLD = 5

) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  fifo_we,
    input  wire                  fifo_re,
    input  wire  [BIT_WIDTH-1:0] fifo_din,
    output logic [BIT_WIDTH-1:0] fifo_dout,
    output logic                 fifo_ovalid,
    output logic                 fifo_empty,
    output logic                 fifo_full,
    output logic                 fifo_almost_empty,
    output logic                 fifo_almost_full
);

    localparam int FIFO_WIDTH = $clog2(FIFO_SIZE);

    logic [ FIFO_WIDTH:0] bram_waddr;
    logic [ FIFO_WIDTH:0] bram_raddr;
    logic [ FIFO_WIDTH:0] bram_raddr_prev;

    logic                 bram_we;
    logic                 bram_re;
    wire  [BIT_WIDTH-1:0] bram_din;
    logic  [BIT_WIDTH-1:0] bram_dout;

    logic [ FIFO_WIDTH:0] fifo_count;


    assign bram_din  = fifo_din;
    assign fifo_dout = bram_dout;


    // bram #(
    //     .FIFO_SIZE(FIFO_SIZE),
    //     .BIT_WIDTH(BIT_WIDTH)
    // ) bram_inst (
    //     .clk,
    //     .rst_n,
    //     .bram_we,
    //     .bram_re,
    //     .bram_raddr,
    //     .bram_waddr,
    //     .bram_din,
    //     .bram_dout
    // );


   wire [BIT_WIDTH-1:0] dram_dout;
 
   dram #(
        .FIFO_SIZE(FIFO_SIZE),
        .BIT_WIDTH(BIT_WIDTH)
    ) dram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .dram_we(bram_we),
        //.dram_re(bram_re),
        .dram_raddr(bram_raddr),
        .dram_waddr(bram_waddr),
        .dram_din(bram_din),
        .dram_dout(dram_dout)
    );
    always_ff @(posedge clk) begin
       if(!rst_n) begin
          bram_dout <= BIT_WIDTH'('d0); 
       end
       else if(bram_re)begin
          bram_dout <= dram_dout;
       end
       else begin
          bram_dout <= bram_dout;
       end
    end
   

    assign bram_we = fifo_we && !fifo_full;
    assign bram_re = fifo_re && !fifo_empty;

    //out valid signal 
    always_ff @(posedge clk) begin : block_valid
        if (!rst_n) begin
            fifo_ovalid <= 1'b0;
        end else begin
            fifo_ovalid <= bram_re & !fifo_empty;
        end
    end

   //assign fifo_ovalid = bram_re;



    always_ff @(posedge clk) begin : block_waddr
        if (!rst_n) begin
            bram_waddr <= (FIFO_WIDTH + 1)'('b1);
        end else begin
            if (bram_we) begin
                bram_waddr <= ((FIFO_SIZE - 1) == bram_waddr) ? (FIFO_WIDTH+1)'('b0) : bram_waddr + (FIFO_WIDTH+1)'('b1);
            end else begin
                bram_waddr <= bram_waddr;
            end
        end
    end



    always_ff @(posedge clk) begin : block_raddr_prev
        if (!rst_n) begin
            bram_raddr_prev <= (FIFO_WIDTH + 1)'('d0);
        end else begin
            if (bram_re) begin
                bram_raddr_prev <= ((FIFO_SIZE - 1) == bram_raddr_prev) ? (FIFO_WIDTH+1)'('d0) : bram_raddr_prev + (FIFO_WIDTH+1)'('b1);
            end else begin
                bram_raddr_prev <= bram_raddr_prev;
            end
        end
    end


    always_comb begin : block_raddr
        bram_raddr = ((FIFO_SIZE - 1) == bram_raddr_prev) ? (FIFO_WIDTH+1)'('b0) :  bram_raddr_prev + (FIFO_WIDTH+1)'('d1);
    end


    assign fifo_full  = (bram_waddr == bram_raddr_prev);
    assign fifo_empty = (bram_raddr == bram_waddr);
    // assign full = waddr_in == raddr;
    // assign empty = waddr == raddr;


    //Calculate the FIFO count
    always_comb begin : block_fifo_count
        if (bram_waddr >= bram_raddr) begin
            fifo_count = bram_waddr - bram_raddr;
        end else begin
            fifo_count = FIFO_SIZE - bram_raddr + bram_waddr;
        end
    end

    //Almost full and alomost empty signals
    always_ff @(posedge clk) begin : block_almost_full
        if (!rst_n) begin
            fifo_almost_full <= 1'b0;
        end else begin
            fifo_almost_full <= (fifo_count >= ALMOST_FULL_THRESHOLD);
        end
    end
    always_ff @(posedge clk) begin : block_almost_empty
        if (!rst_n) begin
            fifo_almost_empty <= 1'b0;
        end else begin
            fifo_almost_empty <= (fifo_count <= ALMOST_EMPTY_THRESHOLD);
        end
    end



endmodule

`default_nettype wire
