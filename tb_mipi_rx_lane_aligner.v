`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Modos
// Engineer: Wenting Zhang
// 
// Create Date:    03:07:56 11/11/2021 
// Design Name:    caster
// Module Name:    tb_mipi_rx_lane_aligner 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//   lane aligner testbench adapted from circuitvalley/mipi_csi_receiver_FPGA
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tb_mipi_lane_aligner(
    );

    reg clk;
    reg rst;
    reg [3:0] bytes_valid;
    reg [31:0] din;
    wire [31:0] dout;
    wire valid;
    wire error;

    mipi_lane_aligner #(
        .DEPTH(7)
    )
    mipi_lane_aligner(
        .clk(clk),
        .rst(rst),
        .din(din),
        .validin(bytes_valid),
        .dout(dout),
        .validout(valid),
        .error(error)
    );
    
    task sendbytes;
        input [31:0] d;
        begin
            din = d;
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
        bytes_valid = 4'h0;
        reset();

        sendbytes(32'h00000000);
        rst = 1'h1;
        sendbytes(32'h00000000);
        rst = 1'h0;
        sendbytes(32'h00000000);
        sendbytes(32'h00000000);
        bytes_valid[1] = 1'h1;
        sendbytes(32'h0000B800);
        sendbytes(32'h00001100);
        sendbytes(32'h00002200);
        sendbytes(32'h00003300);
        bytes_valid[2] = 1'h1;
        bytes_valid[3] = 1'h1;
        sendbytes(32'hB8B84400);
        bytes_valid[0] = 1'h1;
        sendbytes(32'h111155B8);
        sendbytes(32'h22226611);
        sendbytes(32'h33337722);
        sendbytes(32'h44448833);
        bytes_valid[1] = 1'h0;
        sendbytes(32'h55556644);
        sendbytes(32'h66667755);
        sendbytes(32'h77778866);

        sendbytes(32'h88889977);
        bytes_valid[2] = 1'h0;
        bytes_valid[3] = 1'h0;
        
        sendbytes(32'h9999AA88);
        bytes_valid[0] = 1'h0;
        sendbytes(32'h00000000);
        sendbytes(32'h00000000);
        sendbytes(32'h00000000);
        sendbytes(32'h00000000);
        
        sendbytes(32'h00000000);
        sendbytes(32'h00000000);
        sendbytes(32'h00000000);
        sendbytes(32'h00000000);
        sendbytes(32'h00000000);
        bytes_valid[1] = 1'h1;
        sendbytes(32'h0000B800);
        sendbytes(32'h00001100);
        bytes_valid[2] = 1'h1;
        bytes_valid[3] = 1'h1;
        sendbytes(32'hB8B82200);
        bytes_valid[0] = 1'h1;
        sendbytes(32'h111133B8);
        sendbytes(32'h22224411);
        sendbytes(32'h33335522);
        sendbytes(32'h4444663);
        sendbytes(32'h5555774);
        sendbytes(32'h66668855);
        bytes_valid[1] = 1'h0;
        sendbytes(32'h77778866);

        sendbytes(32'h88889977);
        bytes_valid[2] = 1'h0;
        bytes_valid[3] = 1'h0;

        sendbytes(32'h9999AA88);
        bytes_valid[0] = 1'h0;
        
        $finish;
    end

endmodule
