`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:52:45 06/03/2022 
// Design Name: 
// Module Name:    dff_sync 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dff_sync(
    input wire i,
    input wire clko,
    output wire o
    );

    reg sync_dff_1, sync_dff_2;
    always @(posedge clko) begin
        sync_dff_1 <= i;
        sync_dff_2 <= sync_dff_1;
    end
    assign o = sync_dff_2;;

endmodule
