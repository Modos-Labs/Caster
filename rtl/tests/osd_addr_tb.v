`timescale 1ns / 1ps
`default_nettype none

module osd_addr_tb;

    reg [7:0] y;
    reg [5:0] x_byte;
    wire [12:0] addr;

    osd_addr uut (
        .y(y),
        .x_byte(x_byte),
        .addr(addr)
    );

    task expect_addr;
        input [7:0] test_y;
        input [5:0] test_x_byte;
        input [12:0] expected;
        begin
            y = test_y;
            x_byte = test_x_byte;
            #1;
            if (addr !== expected) begin
                $display("FAIL: y=%0d x_byte=%0d expected %0d got %0d",
                    test_y, test_x_byte, expected, addr);
                $finish;
            end
        end
    endtask

    initial begin
        expect_addr(8'd0, 6'd0, 13'd0);
        expect_addr(8'd0, 6'd39, 13'd39);
        expect_addr(8'd1, 6'd0, 13'd40);
        expect_addr(8'd1, 6'd39, 13'd79);
        expect_addr(8'd199, 6'd0, 13'd7960);
        expect_addr(8'd199, 6'd39, 13'd7999);
        $display("osd_addr_tb completed");
        $finish;
    end

endmodule

`default_nettype wire
