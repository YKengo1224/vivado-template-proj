`default_nettype none
interface AXIS_if #(
    parameter int BITWIDTH = -1
) (
    input wire aclk,
    input wire aresetn
);

    logic [BITWIDTH-1:0] tdata;
    logic                tlast;
    logic                tuser;
    logic                tvalid;
    // logic                tready;

   modport master(output tdata, tlast, tuser, tvalid); //, input tready);
   modport slave(input .clk(aclk), .rst_n(aresetn), tdata, tlast, tuser, tvalid);
//, output tready);
   

endinterface
`default_nettype wire

