`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:57:21 11/12/2021 
// Design Name: 
// Module Name:    tb_mipi_rx_packet_slicer 
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
module tb_mipi_rx_packet_slicer(
    );

    reg clk;
    reg rst;
    reg validin;
    reg [31:0] din;
    wire [31:0] dout;
    wire validout;
    wire pktheader;
    
    mipi_rx_packet_slicer mipi_rx_packet_slicer(
        .clk(clk),
        .rst(rst),
        .din(din),
        .validin(validin),
        .dout(dout),
        .validout(validout),
        .pktheader(pktheader)
    );
    
    reg [31:0] dbuf;
    reg validbuf;
    always @(posedge clk) begin
        din <= dbuf;
        validin <= validbuf; 
    end
    
    task sendbytes;
        input [31:0] d;
        input v;
        begin
            dbuf = d;
            validbuf = v;
            clk = 1'b1;
            #4
            clk = 1'b0;
            #4;
        end
    endtask
    
    task reset;
        begin
            clk = 1'b0;
            rst = 1'b1;
            #4
            clk = 1'b1;
            #4;
            clk = 1'b0;
            rst = 1'b0;
            #4;
        end
    endtask
    
    initial begin
        sendbytes(32'h00000000, 1'b0);
    
        reset();
        
        // send 2 short packets, should come out straight
        sendbytes(32'h00000001, 1'b1);
        sendbytes(32'h00000011, 1'b1);
        
        // send a long packet, but aligned
        sendbytes(32'h0000060e, 1'b1);
        sendbytes(32'h44332211, 1'b1);
        sendbytes(32'h00006655, 1'b1);
        
        // send another short packet
        sendbytes(32'h00000011, 1'b1);
        
        // send a long packet, not aligned in the end
        sendbytes(32'h0000040e, 1'b1);
        sendbytes(32'h44332211, 1'b1);
        sendbytes(32'h00110000, 1'b1); // and a short packet
        sendbytes(32'h00010000, 1'b1); // another short packet
        sendbytes(32'h030e0000, 1'b1); // another unaligned long
        sendbytes(32'h22110000, 1'b1);
        sendbytes(32'h01000033, 1'b1); // followed by a short
        sendbytes(32'h0e000000, 1'b1); // and a long
        sendbytes(32'h11000002, 1'b1);
        sendbytes(32'h0e000022, 1'b1); // a long again
        sendbytes(32'h11000003, 1'b1);
        sendbytes(32'h00003322, 1'b1);
        sendbytes(32'h00cdab11, 1'b1); // short
        sendbytes(32'h0000030e, 1'b1); // long
        sendbytes(32'h00332211, 1'b1);
        sendbytes(32'h00030e00, 1'b1); // long
        sendbytes(32'h33221100, 1'b1);
        sendbytes(32'hab110000, 1'b1); // short
        sendbytes(32'h000000cd, 1'b1);
        
        sendbytes(32'hffffffff, 1'b0);
        sendbytes(32'hffffffff, 1'b0);
        
        $finish;
    end

endmodule
