`timescale 1ns / 1ps
`default_nettype none

module vin_source_ctrl_tb;

    parameter CLK_PERIOD = 10;

    reg clk;
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    reg rst;
    reg [1:0] request_source;
    reg live_valid;
    reg live_vsync;
    reg internal_frame_done;
    reg memif_quiescent;
    wire [2:0] selected_source;
    wire stop_new_frame;
    wire source_reset;
    wire live_selected;
    wire internal_selected;
    wire live_lost;
    wire [2:0] state_dbg;

    localparam REQ_INTERNAL = 2'd0;
    localparam REQ_DPI = 2'd1;
    localparam REQ_FPDLINK = 2'd2;
    localparam SRC_INTERNAL = 3'd0;
    localparam SRC_DPI = 3'd1;
    localparam SRC_FPDLINK = 3'd2;
    localparam STATE_LOST = 3'd6;

    vin_source_ctrl uut (
        .clk(clk),
        .rst(rst),
        .request_source(request_source),
        .live_valid(live_valid),
        .live_vsync(live_vsync),
        .internal_frame_done(internal_frame_done),
        .memif_quiescent(memif_quiescent),
        .selected_source(selected_source),
        .stop_new_frame(stop_new_frame),
        .source_reset(source_reset),
        .live_selected(live_selected),
        .internal_selected(internal_selected),
        .live_lost(live_lost),
        .state_dbg(state_dbg)
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

    task reset_ctrl;
        begin
            rst = 1'b1;
            request_source = REQ_INTERNAL;
            live_valid = 1'b0;
            live_vsync = 1'b0;
            internal_frame_done = 1'b0;
            memif_quiescent = 1'b0;
            repeat (4) tick();
            rst = 1'b0;
            repeat (2) tick();
        end
    endtask

    initial begin
        $dumpfile("vin_source_ctrl_tb.vcd");
        $dumpvars(0, vin_source_ctrl_tb);

        reset_ctrl();
        if (!internal_selected || live_selected || live_lost ||
                selected_source !== SRC_INTERNAL)
            fail("boots internal");

        request_source = REQ_DPI;
        live_valid = 1'b1;
        repeat (2) tick();
        if (!internal_selected || stop_new_frame)
            fail("waits for internal frame boundary before quiesce");
        internal_frame_done = 1'b1;
        tick();
        internal_frame_done = 1'b0;
        if (!stop_new_frame || source_reset)
            fail("quiesce requested before reset");
        repeat (4) tick();
        if (!stop_new_frame || source_reset)
            fail("waits for memif quiescent");
        memif_quiescent = 1'b1;
        tick();
        if (!source_reset)
            fail("source reset asserts after quiesce");
        repeat (8) tick();
        live_vsync = 1'b1;
        tick();
        live_vsync = 1'b0;
        tick();
        if (!live_selected || selected_source !== SRC_DPI || source_reset ||
                stop_new_frame)
            fail("valid live enters DPI live state");

        live_valid = 1'b0;
        tick();
        if (!live_lost || state_dbg !== STATE_LOST ||
                selected_source !== SRC_DPI || internal_selected)
            fail("live loss enters lost state");

        reset_ctrl();
        request_source = REQ_FPDLINK;
        repeat (5) tick();
        if (!internal_selected || stop_new_frame || source_reset)
            fail("invalid live stays internal");

        reset_ctrl();
        request_source = REQ_DPI;
        live_valid = 1'b1;
        internal_frame_done = 1'b1;
        memif_quiescent = 1'b1;
        tick();
        internal_frame_done = 1'b0;
        repeat (2) tick();
        request_source = REQ_FPDLINK;
        tick();
        if (!internal_selected || selected_source !== SRC_INTERNAL)
            fail("requested source change rearms from internal");

        $display("vin_source_ctrl_tb completed at time %0t", $time);
        $finish;
    end

endmodule

`default_nettype wire
