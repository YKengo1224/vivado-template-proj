`ifndef PARAM_PKG_SV
`define PARAM_PKG_SV

`default_nettype none

package param_pkg;
    parameter int MCU_SIZE = 8;
    parameter int RGB_BITWIDTH = 8;
    parameter int YUV_BITWIDTH = RGB_BITWIDTH;
    parameter int DCT_BITWIDTH = 16;
    parameter int QUAN_BITWIDTH = 12;
    parameter int DCT_PIXEL_BITWIDTH = DCT_BITWIDTH * 3;
    parameter int QUAN_PIXEL_BITWIDTH = QUAN_BITWIDTH * 3;


endpackage

`default_nettype wire
`endif
