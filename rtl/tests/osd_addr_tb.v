`timescale 1ns / 1ps
`default_nettype none

module osd_addr_tb;

    reg [8:0] y;
    reg [7:0] x_group;
    reg scale_2x;
    wire [12:0] addr;
    reg [7:0] overlay_byte;
    reg [1:0] overlay_x_group;
    wire [3:0] overlay_2x;

    osd_addr uut (
        .y(y),
        .x_group(x_group),
        .scale_2x(scale_2x),
        .addr(addr)
    );

    osd_overlay_expand expand_uut (
        .osd_byte(overlay_byte),
        .x_group(overlay_x_group),
        .overlay_2x(overlay_2x)
    );

    task expect_addr;
        input [8:0] test_y;
        input [7:0] test_x_group;
        input [12:0] expected;
        begin
            scale_2x = 1'b0;
            y = test_y;
            x_group = test_x_group;
            #1;
            if (addr !== expected) begin
                $display("FAIL: y=%0d x_group=%0d expected %0d got %0d",
                    test_y, test_x_group, expected, addr);
                $finish;
            end
        end
    endtask

    task expect_addr_scaled;
        input [8:0] test_y;
        input [7:0] test_x_group;
        input [12:0] expected;
        begin
            scale_2x = 1'b1;
            y = test_y;
            x_group = test_x_group;
            #1;
            if (addr !== expected) begin
                $display("FAIL scaled: y=%0d x_group=%0d expected %0d got %0d",
                    test_y, test_x_group, expected, addr);
                $finish;
            end
        end
    endtask

    task expect_overlay_2x;
        input [7:0] test_byte;
        input [1:0] test_x_group;
        input [3:0] expected;
        begin
            overlay_byte = test_byte;
            overlay_x_group = test_x_group;
            #1;
            if (overlay_2x !== expected) begin
                $display("FAIL overlay: byte=%b x_group=%0d expected %b got %b",
                    test_byte, test_x_group, expected, overlay_2x);
                $finish;
            end
        end
    endtask

    initial begin
        scale_2x = 1'b0;
        expect_addr(8'd0, 6'd0, 13'd0);
        expect_addr(8'd0, 8'd78, 13'd39);
        expect_addr(8'd1, 8'd0, 13'd40);
        expect_addr(8'd1, 8'd78, 13'd79);
        expect_addr(8'd199, 6'd0, 13'd7960);
        expect_addr(8'd199, 8'd78, 13'd7999);
        expect_addr_scaled(8'd0, 6'd0, 13'd0);
        expect_addr_scaled(8'd0, 6'd1, 13'd0);
        expect_addr_scaled(8'd1, 6'd0, 13'd0);
        expect_addr_scaled(8'd1, 6'd1, 13'd0);
        expect_addr_scaled(8'd0, 8'd4, 13'd1);
        expect_addr_scaled(8'd1, 8'd7, 13'd1);
        expect_addr_scaled(8'd2, 6'd0, 13'd40);
        expect_addr_scaled(8'd2, 6'd2, 13'd40);
        expect_addr_scaled(8'd3, 6'd3, 13'd40);
        expect_addr_scaled(9'd255, 8'd0, 13'd5080);
        expect_addr_scaled(9'd256, 8'd0, 13'd5120);
        expect_addr_scaled(9'd398, 8'd0, 13'd7960);
        expect_addr_scaled(9'd399, 8'd156, 13'd7999);
        expect_overlay_2x(8'b1100_0110, 2'd0, 4'b1111);
        expect_overlay_2x(8'b1100_0110, 2'd1, 4'b0000);
        expect_overlay_2x(8'b1100_0110, 2'd2, 4'b0011);
        expect_overlay_2x(8'b1100_0110, 2'd3, 4'b1100);
        $display("osd_addr_tb completed");
        $finish;
    end

endmodule

`default_nettype wire
