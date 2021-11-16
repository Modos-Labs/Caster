`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting
// 
// Create Date:    02:38:10 11/11/2021 
// Design Name:    caster
// Module Name:    tb_mipi_rx_byte_aligner 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   byte aligner testbench adapted from circuitvalley/mipi_csi_receiver_FPGA
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tb_mipi_byte_aligner(
    );
    
    reg clk;
    reg rst;
    reg [7:0] din;
    wire [7:0] dout;
    wire valid;

    mipi_byte_aligner mipi_byte_aligner(
        .clk(clk),
        .rst(rst),
        .din(din),
        .dout(dout),
        .valid(valid)
    );
    
    reg [7:0] dbuf;
    always @(posedge clk)
        din <= dbuf;
    
    task sendbyte;
        input [7:0] d;
        begin
            dbuf = d;
            clk = 1'b1;
            #3
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
        reset();
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h77);
        sendbyte(8'h25);
        sendbyte(8'h42);
        sendbyte(8'hCE);
        sendbyte(8'h22);
        sendbyte(8'h22);
        sendbyte(8'h22);
        sendbyte(8'h62);
        sendbyte(8'h30);
        sendbyte(8'h22);
        sendbyte(8'h02);
        reset();
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h70);
        sendbyte(8'h41);
        sendbyte(8'hA0);
        sendbyte(8'h22);
        sendbyte(8'h72);
        sendbyte(8'h22);
        sendbyte(8'h22);
        sendbyte(8'h22);
        sendbyte(8'h3A);
        sendbyte(8'h22);
        sendbyte(8'h22);
        reset();
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h5C);
        sendbyte(8'h95);
        sendbyte(8'h08);
        sendbyte(8'h1F);
        sendbyte(8'h08);
        sendbyte(8'h08);
        sendbyte(8'h88);
        sendbyte(8'h08);
        sendbyte(8'h17);
        sendbyte(8'h08);
        sendbyte(8'h08);
        reset();
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h5C);
        sendbyte(8'h30);
        sendbyte(8'h88);
        sendbyte(8'h08);
        sendbyte(8'hA9);
        sendbyte(8'h88);
        sendbyte(8'h88);
        sendbyte(8'h08);
        sendbyte(8'h17);
        sendbyte(8'h08);
        sendbyte(8'h08);
        reset();
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'h00);
        sendbyte(8'hE0); 
        sendbyte(8'h82);
        sendbyte(8'h45);
        sendbyte(8'h40);
        sendbyte(8'hC4);
        sendbyte(8'h45);
        sendbyte(8'h40);
        sendbyte(8'h08);
        sendbyte(8'h17);
        sendbyte(8'h08);
        sendbyte(8'h08);
        
        $finish;
    end

endmodule
