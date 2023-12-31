// Copyright Modos / Wenting Zhang 2023
//
// This source describes Open Hardware and is licensed under the CERN-OHL-P v2
//
// You may redistribute and modify this documentation and make products using
// it under the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl). This
// documentation is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A
// PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable conditions
//
// linear_4b_quantizer.v
// LUT for finding the closest quantized output in the linear space
//
`default_nettype none
`timescale 1ns / 1ps
module linear_4b_quantizer (
    input wire [7:0] in,
    output reg [3:0] index,
    output reg [7:0] linear
);

    always @(in[7:2]) begin
        case (in[7:2])
        0: begin index = 0; linear = 0; end
        1: begin index = 1; linear = 1; end
        2: begin index = 2; linear = 3; end
        3: begin index = 3; linear = 7; end
        4: begin index = 4; linear = 13; end
        5: begin index = 5; linear = 22; end
        6: begin index = 5; linear = 22; end
        7: begin index = 5; linear = 22; end
        8: begin index = 6; linear = 33; end
        9: begin index = 6; linear = 33; end
        10: begin index = 6; linear = 33; end
        11: begin index = 7; linear = 47; end
        12: begin index = 7; linear = 47; end
        13: begin index = 7; linear = 47; end
        14: begin index = 7; linear = 47; end
        15: begin index = 8; linear = 63; end
        16: begin index = 8; linear = 63; end
        17: begin index = 8; linear = 63; end
        18: begin index = 8; linear = 63; end
        19: begin index = 9; linear = 82; end
        20: begin index = 9; linear = 82; end
        21: begin index = 9; linear = 82; end
        22: begin index = 9; linear = 82; end
        23: begin index = 9; linear = 82; end
        24: begin index = 10; linear = 104; end
        25: begin index = 10; linear = 104; end
        26: begin index = 10; linear = 104; end
        27: begin index = 10; linear = 104; end
        28: begin index = 10; linear = 104; end
        29: begin index = 10; linear = 104; end
        30: begin index = 11; linear = 128; end
        31: begin index = 11; linear = 128; end
        32: begin index = 11; linear = 128; end
        33: begin index = 11; linear = 128; end
        34: begin index = 11; linear = 128; end
        35: begin index = 11; linear = 128; end
        36: begin index = 12; linear = 156; end
        37: begin index = 12; linear = 156; end
        38: begin index = 12; linear = 156; end
        39: begin index = 12; linear = 156; end
        40: begin index = 12; linear = 156; end
        41: begin index = 12; linear = 156; end
        42: begin index = 12; linear = 156; end
        43: begin index = 13; linear = 186; end
        44: begin index = 13; linear = 186; end
        45: begin index = 13; linear = 186; end
        46: begin index = 13; linear = 186; end
        47: begin index = 13; linear = 186; end
        48: begin index = 13; linear = 186; end
        49: begin index = 13; linear = 186; end
        50: begin index = 13; linear = 186; end
        51: begin index = 14; linear = 219; end
        52: begin index = 14; linear = 219; end
        53: begin index = 14; linear = 219; end
        54: begin index = 14; linear = 219; end
        55: begin index = 14; linear = 219; end
        56: begin index = 14; linear = 219; end
        57: begin index = 14; linear = 219; end
        58: begin index = 14; linear = 219; end
        59: begin index = 14; linear = 219; end
        60: begin index = 15; linear = 255; end
        61: begin index = 15; linear = 255; end
        62: begin index = 15; linear = 255; end
        63: begin index = 15; linear = 255; end
        endcase
    end

endmodule
`default_nettype wire
