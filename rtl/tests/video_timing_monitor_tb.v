`timescale 1ns / 1ps
`default_nettype none

module video_timing_monitor_tb;

    parameter CLK_PERIOD = 10;

    reg clk;
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    reg rst;
    reg lock;
    reg vsync;
    reg hsync;
    reg de;
    reg [11:0] exp_hact;
    reg [11:0] exp_vact;
    wire stable;
    wire supported;
    wire [11:0] meas_hact;
    wire [11:0] meas_vact;
    wire [11:0] meas_htotal;
    wire [11:0] meas_vtotal;
    wire [3:0] stable_frames;

    video_timing_monitor uut (
        .clk(clk),
        .rst(rst),
        .lock(lock),
        .vsync(vsync),
        .hsync(hsync),
        .de(de),
        .exp_hact(exp_hact),
        .exp_vact(exp_vact),
        .stable(stable),
        .supported(supported),
        .meas_hact(meas_hact),
        .meas_vact(meas_vact),
        .meas_htotal(meas_htotal),
        .meas_vtotal(meas_vtotal),
        .stable_frames(stable_frames)
    );

    task fail;
        input [511:0] message;
        begin
            $display("FAIL: %0s at time %0t", message, $time);
            $fatal(1);
        end
    endtask

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task send_line;
        input integer active_clocks;
        input integer total_clocks;
        integer i;
        begin
            for (i = 0; i < total_clocks; i = i + 1) begin
                hsync = (i == 0);
                de = (i >= 2) && (i < (2 + active_clocks));
                tick();
            end
            hsync = 1'b0;
            de = 1'b0;
        end
    endtask

    task send_frame;
        input integer active_clocks;
        input integer active_lines;
        input integer total_clocks;
        input integer total_lines;
        integer y;
        begin
            for (y = 0; y < total_lines; y = y + 1) begin
                if (y < active_lines)
                    send_line(active_clocks, total_clocks);
                else
                    send_line(0, total_clocks);
            end
            vsync = 1'b1;
            tick();
            vsync = 1'b0;
        end
    endtask

    task reset_monitor;
        begin
            rst = 1'b1;
            lock = 1'b0;
            vsync = 1'b0;
            hsync = 1'b0;
            de = 1'b0;
            exp_hact = 12'd8;
            exp_vact = 12'd4;
            repeat (4) tick();
            rst = 1'b0;
            lock = 1'b1;
            repeat (2) tick();
        end
    endtask

    initial begin
        $dumpfile("video_timing_monitor_tb.vcd");
        $dumpvars(0, video_timing_monitor_tb);

        reset_monitor();
        send_frame(8, 4, 12, 6);
        if (stable || supported)
            fail("single frame must not be stable");
        send_frame(8, 4, 12, 6);
        if (stable || supported)
            fail("two frames must not be stable");
        send_frame(8, 4, 12, 6);
        if (!stable || !supported)
            fail("valid timing stabilizes after three frames");
        if (meas_hact !== 12'd8 || meas_vact !== 12'd4 ||
                meas_htotal !== 12'd12 || meas_vtotal !== 12'd6)
            fail("valid timing measurement");

        reset_monitor();
        send_frame(7, 4, 12, 6);
        send_frame(7, 4, 12, 6);
        send_frame(7, 4, 12, 6);
        if (!stable || supported)
            fail("wrong hact is stable but unsupported");

        reset_monitor();
        send_frame(8, 3, 12, 6);
        send_frame(8, 3, 12, 6);
        send_frame(8, 3, 12, 6);
        if (!stable || supported)
            fail("wrong vact is stable but unsupported");

        reset_monitor();
        send_frame(8, 4, 12, 6);
        send_frame(8, 4, 12, 6);
        send_frame(8, 4, 12, 6);
        lock = 1'b0;
        tick();
        if (stable || supported || (stable_frames != 4'd0))
            fail("lock drop clears stable state");

        reset_monitor();
        send_frame(8, 4, 12, 6);
        send_frame(8, 4, 12, 6);
        send_frame(7, 4, 12, 6);
        if (stable || supported || (stable_frames != 4'd1))
            fail("one bad frame resets stable counter");

        $display("video_timing_monitor_tb completed at time %0t", $time);
        $finish;
    end

endmodule

`default_nettype wire
