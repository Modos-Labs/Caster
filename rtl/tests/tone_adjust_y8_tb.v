`timescale 1ns / 1ps
`default_nettype none

module tone_adjust_y8_tb;

    parameter CLK_PERIOD = 10;

    reg clk;
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    reg [31:0] vin;
    wire [31:0] vout;
    reg [7:0] tone_addr;
    reg [7:0] tone_wr;
    reg tone_we;

    tone_adjust_y8 uut (
        .clk(clk),
        .i_pixel(vin),
        .o_pixel(vout),
        .tone_addr(tone_addr),
        .tone_wr(tone_wr),
        .tone_we(tone_we)
    );

    task fail;
        input [255:0] message;
        begin
            $display("FAIL: %0s at time %0t", message, $time);
            $finish;
        end
    endtask

    task write_lut;
        input [7:0] addr;
        input [7:0] value;
        begin
            tone_addr = addr;
            tone_wr = value;
            tone_we = 1'b1;
            @(posedge clk);
            #1;
            tone_we = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("tone_adjust_y8_tb.vcd");
        $dumpvars(0, tone_adjust_y8_tb);

        vin = 32'h00000000;
        tone_addr = 8'd0;
        tone_wr = 8'd0;
        tone_we = 1'b0;
        repeat (2) @(posedge clk);

        write_lut(8'h10, 8'ha1);
        write_lut(8'h20, 8'hb2);
        write_lut(8'h30, 8'hc3);
        write_lut(8'h40, 8'hd4);

        vin = 32'h40302010;
        @(posedge clk);
        #1;
        if (vout !== 32'hd4c3b2a1)
            fail("four-lane luma lookup");

        write_lut(8'h20, 8'h55);
        vin = 32'h20202020;
        @(posedge clk);
        #1;
        if (vout !== 32'h55555555)
            fail("single CSR write updates all lanes");

        $display("tone_adjust_y8_tb completed at time %0t", $time);
        $finish;
    end

endmodule
`default_nettype wire
