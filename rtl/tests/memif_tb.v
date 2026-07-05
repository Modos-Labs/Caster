`timescale 1ns / 1ps
`default_nettype none

module memif_tb;

    parameter CLK_PERIOD = 10;

    reg clk;
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    reg rst;
    reg enable;
    reg vsync;
    reg [23:0] frame_bytes;
    wire [127:0] pix_read;
    wire pix_read_valid;
    wire pix_read_ready;
    reg [127:0] pix_write;
    reg pix_write_valid;
    wire pix_write_ready;
    wire mig_cmd_en;
    wire [2:0] mig_cmd_instr;
    wire [5:0] mig_cmd_bl;
    wire [29:0] mig_cmd_byte_addr;
    reg mig_cmd_full;
    wire mig_wr_en;
    wire [15:0] mig_wr_mask;
    wire [127:0] mig_wr_data;
    reg mig_wr_empty;
    reg mig_wr_full;
    wire mig_rd_en;
    reg [127:0] mig_rd_data;
    reg mig_rd_empty;
    wire error;
    wire rd_idle;
    wire wr_idle;
    wire issue_idle;
    wire [1:0] rd_state_dbg;
    wire [2:0] wr_state_dbg;
    wire mig_rd_empty_dbg;
    wire mig_wr_empty_dbg;

    memif uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .vsync(vsync),
        .frame_bytes(frame_bytes),
        .pix_read(pix_read),
        .pix_read_valid(pix_read_valid),
        .pix_read_ready(pix_read_ready),
        .pix_write(pix_write),
        .pix_write_valid(pix_write_valid),
        .pix_write_ready(pix_write_ready),
        .mig_cmd_en(mig_cmd_en),
        .mig_cmd_instr(mig_cmd_instr),
        .mig_cmd_bl(mig_cmd_bl),
        .mig_cmd_byte_addr(mig_cmd_byte_addr),
        .mig_cmd_empty(1'b1),
        .mig_cmd_full(mig_cmd_full),
        .mig_wr_en(mig_wr_en),
        .mig_wr_mask(mig_wr_mask),
        .mig_wr_data(mig_wr_data),
        .mig_wr_empty(mig_wr_empty),
        .mig_wr_full(mig_wr_full),
        .mig_wr_count(7'd0),
        .mig_wr_underrun(1'b0),
        .mig_rd_en(mig_rd_en),
        .mig_rd_data(mig_rd_data),
        .mig_rd_full(1'b0),
        .mig_rd_empty(mig_rd_empty),
        .mig_rd_overflow(1'b0),
        .mig_rd_count(7'd0),
        .error(error),
        .rd_idle(rd_idle),
        .wr_idle(wr_idle),
        .issue_idle(issue_idle),
        .rd_state_dbg(rd_state_dbg),
        .wr_state_dbg(wr_state_dbg),
        .mig_rd_empty_dbg(mig_rd_empty_dbg),
        .mig_wr_empty_dbg(mig_wr_empty_dbg)
    );

    assign pix_read_ready = 1'b1;

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

    integer i;

    initial begin
        $dumpfile("memif_tb.vcd");
        $dumpvars(0, memif_tb);

        rst = 1'b1;
        enable = 1'b0;
        vsync = 1'b0;
        frame_bytes = 24'd256;
        pix_write = 128'h0123456789abcdef0123456789abcdef;
        pix_write_valid = 1'b0;
        mig_cmd_full = 1'b0;
        mig_wr_empty = 1'b1;
        mig_wr_full = 1'b0;
        mig_rd_data = 128'h0;
        mig_rd_empty = 1'b1;
        repeat (4) tick();
        rst = 1'b0;
        repeat (2) tick();

        if (!rd_idle || !wr_idle || !issue_idle || error)
            fail("memif idle debug outputs after reset");
        if (rd_state_dbg !== 2'd0 || wr_state_dbg !== 3'd0)
            fail("memif state debug values after reset");
        if (!mig_rd_empty_dbg || !mig_wr_empty_dbg)
            fail("MIG empty debug mirrors inputs");

        enable = 1'b1;
        vsync = 1'b1;
        tick();
        vsync = 1'b0;

        for (i = 0; i < 64; i = i + 1) begin
            pix_write_valid = 1'b1;
            mig_rd_empty = (i < 8);
            tick();
        end

        enable = 1'b0;
        pix_write_valid = 1'b0;
        mig_rd_empty = 1'b1;
        repeat (16) tick();

        if (!rd_idle || !wr_idle || !issue_idle)
            fail("memif returns to idle after frame drain");

        $display("memif_tb completed at time %0t", $time);
        $finish;
    end

endmodule

`default_nettype wire
