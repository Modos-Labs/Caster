`timescale 1ns / 1ps
`default_nettype none

module osd_addr #(
    parameter OSD_STRIDE_BYTES = 40
) (
    input wire [8:0] y,
    input wire [7:0] x_group,
    input wire scale_2x,
    output wire [12:0] addr
);

    wire [7:0] logical_y = scale_2x ? y[8:1] : y[7:0];
    wire [5:0] logical_x_byte = scale_2x ? x_group[7:2] : x_group[6:1];

    generate
        if (OSD_STRIDE_BYTES == 40) begin : gen_stride_40
            assign addr = {logical_y, 5'd0} + {2'd0, logical_y, 3'd0} +
                    {7'd0, logical_x_byte};
        end
        else begin : gen_stride_generic
            assign addr = (logical_y * OSD_STRIDE_BYTES) + logical_x_byte;
        end
    endgenerate

endmodule

module osd_overlay_expand (
    input wire [7:0] osd_byte,
    input wire [1:0] x_group,
    output reg [3:0] overlay_2x
);

    always @(*) begin
        case (x_group)
        2'd0: overlay_2x = {osd_byte[7], osd_byte[7], osd_byte[6], osd_byte[6]};
        2'd1: overlay_2x = {osd_byte[5], osd_byte[5], osd_byte[4], osd_byte[4]};
        2'd2: overlay_2x = {osd_byte[3], osd_byte[3], osd_byte[2], osd_byte[2]};
        default: overlay_2x = {osd_byte[1], osd_byte[1], osd_byte[0], osd_byte[0]};
        endcase
    end

endmodule

`default_nettype wire
