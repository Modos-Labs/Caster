`timescale 1ns / 1ps
`default_nettype none
`include "defines.vh"

module pixel_processing_tb;

    parameter CLK_PERIOD = 10;

    localparam MODE_FAST_MONO_NO_DITHER = 4'd8;
    localparam MODE_FAST_GREY = 4'd11;
    localparam MODE_AUTO_LUT_NO_DITHER = 4'd12;
    localparam STAGE_DONE = 2'd0;
    localparam STAGE_MONO = 2'd1;
    localparam STAGE_HOLD = 2'd2;
    localparam STAGE_GREY = 2'd3;

    localparam NO_DRIVE = 2'b00;
    localparam DRIVE_BLACK = 2'b01;
    localparam DRIVE_WHITE = 2'b10;

    reg clk;
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    reg [3:0] pixel_in;
    wire [1:0] pixel_out;

    reg [15:0] pix_state;
    wire [15:0] proc_bo;

    reg [1:0] proc_lut_rd;
    reg op_valid;
    reg [7:0] op_cmd;
    reg [7:0] op_param;
    reg [7:0] op_framecnt;
    reg [5:0] al_framecnt;
    reg autolut_start;
    reg framecap_en;
    wire pixel_diff;
    wire pixel_activity;
    wire autolut_pending;

    pixel_processing uut (
        .csr_lutframe(6'd29),
        .csr_mindrv(2'd1),
        .csr_b2wframe(6'd6),
        .csr_w2bframe(6'd7),
        .csr_fastg_b2gframe(6'd2),
        .csr_fastg_w2gframe(6'd3),
        .proc_p_or(pixel_in),
        .proc_p_bd(pixel_in[3]),
        .proc_p_n1(pixel_in[3]),
        .proc_p_n4(pixel_in),
        .proc_bi(pix_state),
        .proc_bo(proc_bo),
        .proc_lut_rd(proc_lut_rd),
        .proc_output(pixel_out),
        .op_state(`OP_NORMAL),
        .op_valid(op_valid),
        .op_cmd(op_cmd),
        .op_param(op_param),
        .op_framecnt(op_framecnt),
        .al_framecnt(al_framecnt),
        .autolut_start(autolut_start),
        .framecap_en(framecap_en),
        .pixel_diff(pixel_diff),
        .pixel_activity(pixel_activity),
        .autolut_pending(autolut_pending)
    );

    task fail;
        input [255:0] message;
        begin
            $display("FAIL: %0s at time %0t", message, $time);
            $finish;
        end
    endtask

    task expect1;
        input actual;
        input expected;
        input [255:0] message;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s expected %0b got %0b at time %0t",
                    message, expected, actual, $time);
                $finish;
            end
        end
    endtask

    task expect2;
        input [1:0] actual;
        input [1:0] expected;
        input [255:0] message;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s expected %0b got %0b at time %0t",
                    message, expected, actual, $time);
                $finish;
            end
        end
    endtask

    task expect4;
        input [3:0] actual;
        input [3:0] expected;
        input [255:0] message;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s expected %0d got %0d at time %0t",
                    message, expected, actual, $time);
                $finish;
            end
        end
    endtask

    task expect6;
        input [5:0] actual;
        input [5:0] expected;
        input [255:0] message;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s expected %0d got %0d at time %0t",
                    message, expected, actual, $time);
                $finish;
            end
        end
    endtask

    task commit_pixel;
        begin
            @(posedge clk);
            pix_state <= proc_bo;
            @(negedge clk);
            #1;
        end
    endtask

    integer mono_guard;

    initial begin
        $dumpfile("pixel_processing_tb.vcd");
        $dumpvars(0, pixel_processing_tb);

        pixel_in = 4'd15;
        pix_state = `INIT_FAST_MONO_ND;
        proc_lut_rd = 2'b11;
        op_valid = 1'b0;
        op_cmd = 8'd0;
        op_param = 8'd0;
        op_framecnt = 8'd0;
        al_framecnt = 6'd0;
        autolut_start = 1'b0;
        framecap_en = 1'b1;
        #1;

        $display("Starting runtime timing test...");

        pix_state = {MODE_FAST_MONO_NO_DITHER, 2'b0, 6'd0, 3'd0, 1'b0};
        pixel_in = 4'd15;
        #1;
        expect2(pixel_out, DRIVE_WHITE, "FAST_MONO black-to-white drives white");
        expect6(proc_bo[9:4], 6'd6, "FAST_MONO uses CSR black-to-white frame count");
        expect1(pixel_diff, 1'b1, "FAST_MONO black-to-white reports pixel diff");

        pix_state = {MODE_FAST_MONO_NO_DITHER, 2'b0, 6'd0, 3'd0, 1'b1};
        pixel_in = 4'd0;
        #1;
        expect2(pixel_out, DRIVE_BLACK, "FAST_MONO white-to-black drives black");
        expect6(proc_bo[9:4], 6'd7, "FAST_MONO uses CSR white-to-black frame count");
        expect1(pixel_diff, 1'b1, "FAST_MONO white-to-black reports pixel diff");

        pix_state = {MODE_FAST_GREY, STAGE_DONE, 6'd0, 2'b00, 2'b11};
        pixel_in = 4'd8;
        #1;
        expect2(pixel_out, DRIVE_WHITE, "FAST_GREY same-binary grey update starts binary drive");
        expect2(proc_bo[11:10], STAGE_GREY, "FAST_GREY same-binary update enters GREY");
        expect6(proc_bo[9:4], 6'd8, "FAST_GREY uses CSR white-to-grey frame count plus settle");
        expect1(pixel_diff, 1'b1, "FAST_GREY same-binary update reports pixel diff");

        pix_state = {MODE_FAST_GREY, STAGE_DONE, 6'd0, 2'b00, 2'b00};
        pixel_in = 4'd4;
        #1;
        expect2(pixel_out, DRIVE_BLACK, "FAST_GREY black-to-grey update starts binary drive");
        expect2(proc_bo[11:10], STAGE_GREY, "FAST_GREY black-to-grey update enters GREY");
        expect6(proc_bo[9:4], 6'd7, "FAST_GREY uses CSR black-to-grey frame count plus settle");
        expect1(pixel_diff, 1'b1, "FAST_GREY black-to-grey reports pixel diff");

        pix_state = `INIT_FAST_GREY;
        pixel_in = 4'd0;
        op_valid = 1'b1;
        op_cmd = `OP_EXT_SETMODE;
        op_param = `SETMODE_FAST_MONO_NO_DITHER;
        op_framecnt = 8'd0;
        #1;
        expect2(pixel_out, NO_DRIVE, "SETMODE apply does not leak stale pixel drive");
        expect2(proc_bo[15:14], 2'b10, "SETMODE apply updates pixel mode");
        expect1(pixel_diff, 1'b0, "SETMODE apply suppresses pixel diff");

        op_valid = 1'b0;
        op_cmd = 8'd0;
        op_param = 8'd0;

        $display("Starting AUTO_LUT test...");

        pixel_in = 4'd15;
        pix_state = `INIT_AUTO_LUT_ND;
        al_framecnt = 6'd0;
        autolut_start = 1'b0;
        #1;

        pixel_in = 4'd4;
        #1;
        expect2(pixel_out, DRIVE_BLACK, "settled AUTO_LUT starts mono drive");
        expect2(proc_bo[11:10], STAGE_MONO, "settled AUTO_LUT enters MONO");
        expect1(pixel_diff, 1'b1, "mono start reports pixel diff");
        expect1(pixel_activity, 1'b1, "mono start reports activity");
        commit_pixel();

        mono_guard = 0;
        while (pix_state[11:10] == STAGE_MONO) begin
            commit_pixel();
            mono_guard = mono_guard + 1;
            if (mono_guard > 20)
                fail("AUTO_LUT MONO stage did not finish");
        end

        expect2(pix_state[11:10], STAGE_DONE, "mono completion returns to DONE");
        expect1(pix_state[9], 1'b1, "mono completion marks pending grayscale");
        expect1(pix_state[8], 1'b0, "pending state records black binary screen");
        expect4(pix_state[3:0], 4'd4, "pending state keeps grayscale target");
        expect1(autolut_pending, 1'b1, "pending state is reported to caster");

        pixel_in = 4'd5;
        #1;
        expect2(pixel_out, NO_DRIVE, "same-binary pending target coalesces without drive");
        expect1(pixel_diff, 1'b0, "same-binary pending target coalesce does not report pixel diff");
        expect1(pixel_activity, 1'b1, "pending target coalesce reports activity");
        expect1(proc_bo[9], 1'b1, "coalesced target remains pending");
        expect4(proc_bo[3:0], 4'd5, "coalesced target updates target nibble");
        commit_pixel();

        al_framecnt = 6'd29;
        autolut_start = 1'b1;
        #1;
        expect2(pixel_out, NO_DRIVE, "global release stage transition does not drive");
        expect2(proc_bo[11:10], STAGE_GREY, "global release enters GREY");
        expect4(proc_bo[7:4], 4'd0, "GREY source is normalized binary black");
        expect4(proc_bo[3:0], 4'd5, "GREY target is coalesced target");
        commit_pixel();

        autolut_start = 1'b0;
        #1;
        expect2(pixel_out, proc_lut_rd, "GREY stage drives LUT output while active");

        al_framecnt = 6'd0;
        #1;
        expect2(pixel_out, NO_DRIVE, "GREY final frame commits without overdrive");
        expect2(proc_bo[11:10], STAGE_DONE, "GREY final frame returns to DONE");
        expect1(proc_bo[9], 1'b0, "settled DONE is not pending");
        expect4(proc_bo[3:0], 4'd5, "settled DONE stores final grayscale");

        $display("pixel_processing_tb completed at time %0t", $time);
        $finish;
    end

endmodule
`default_nettype wire
