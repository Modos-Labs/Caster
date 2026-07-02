`timescale 1ns / 1ps
`default_nettype none

module osd_addr #(
    parameter OSD_STRIDE_BYTES = 40
) (
    input wire [7:0] y,
    input wire [5:0] x_byte,
    output wire [12:0] addr
);

    generate
        if (OSD_STRIDE_BYTES == 40) begin : gen_stride_40
            assign addr = {y, 5'd0} + {2'd0, y, 3'd0} + {7'd0, x_byte};
        end
        else begin : gen_stride_generic
            assign addr = (y * OSD_STRIDE_BYTES) + x_byte;
        end
    endgenerate

endmodule

`default_nettype wire
