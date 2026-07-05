`timescale 1ns / 1ps
`default_nettype none
`include "defines.vh"

module csr_tb;

    parameter CLK_PERIOD = 10;

    reg clk;
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    reg rst;
    reg spi_cs;
    reg spi_sck;
    reg spi_mosi;
    wire spi_miso;

    wire [5:0] csr_lut_frame;
    wire [11:0] csr_lut_addr;
    wire [7:0] csr_lut_wr;
    wire csr_lut_we;
    wire csr_osd_en;
    wire [11:0] csr_osd_left;
    wire [11:0] csr_osd_right;
    wire [11:0] csr_osd_top;
    wire [11:0] csr_osd_bottom;
    wire [12:0] csr_osd_addr;
    wire [7:0] csr_osd_wr;
    wire csr_osd_we;
    wire csr_osd_scale_2x;
    wire [7:0] csr_tone_addr;
    wire [7:0] csr_tone_wr;
    wire csr_tone_we;
    wire [11:0] csr_op_left;
    wire [11:0] csr_op_right;
    wire [11:0] csr_op_top;
    wire [11:0] csr_op_bottom;
    wire [7:0] csr_op_param;
    wire [7:0] csr_op_length;
    wire [7:0] csr_op_cmd;
    wire csr_op_en;
    wire csr_en;
    wire [7:0] csr_cfg_vfp;
    wire [7:0] csr_cfg_vsync;
    wire [7:0] csr_cfg_vbp;
    wire [11:0] csr_cfg_vact;
    wire [7:0] csr_cfg_hfp;
    wire [7:0] csr_cfg_hsync;
    wire [7:0] csr_cfg_hbp;
    wire [11:0] csr_cfg_hact;
    wire [23:0] csr_cfg_fbytes;
    wire [1:0] csr_cfg_mindrv;
    wire [5:0] csr_cfg_b2wframe;
    wire [5:0] csr_cfg_w2bframe;
    wire [5:0] csr_cfg_fastg_b2gframe;
    wire [5:0] csr_cfg_fastg_w2gframe;
    wire csr_mirror_en;
    wire csr_blank_input;
    wire [7:0] csr_input_ctrl;
    wire dbg_spi_req_wen;
    wire [7:0] dbg_spi_req_addr;
    wire [7:0] dbg_spi_req_wdata;

    csr uut (
        .clk(clk),
        .rst(rst),
        .spi_cs(spi_cs),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .csr_lut_frame(csr_lut_frame),
        .csr_lut_addr(csr_lut_addr),
        .csr_lut_wr(csr_lut_wr),
        .csr_lut_we(csr_lut_we),
        .csr_osd_en(csr_osd_en),
        .csr_osd_left(csr_osd_left),
        .csr_osd_right(csr_osd_right),
        .csr_osd_top(csr_osd_top),
        .csr_osd_bottom(csr_osd_bottom),
        .csr_osd_addr(csr_osd_addr),
        .csr_osd_wr(csr_osd_wr),
        .csr_osd_we(csr_osd_we),
        .csr_osd_scale_2x(csr_osd_scale_2x),
        .csr_tone_addr(csr_tone_addr),
        .csr_tone_wr(csr_tone_wr),
        .csr_tone_we(csr_tone_we),
        .csr_op_left(csr_op_left),
        .csr_op_right(csr_op_right),
        .csr_op_top(csr_op_top),
        .csr_op_bottom(csr_op_bottom),
        .csr_op_param(csr_op_param),
        .csr_op_length(csr_op_length),
        .csr_op_cmd(csr_op_cmd),
        .csr_op_en(csr_op_en),
        .csr_en(csr_en),
        .csr_cfg_vfp(csr_cfg_vfp),
        .csr_cfg_vsync(csr_cfg_vsync),
        .csr_cfg_vbp(csr_cfg_vbp),
        .csr_cfg_vact(csr_cfg_vact),
        .csr_cfg_hfp(csr_cfg_hfp),
        .csr_cfg_hsync(csr_cfg_hsync),
        .csr_cfg_hbp(csr_cfg_hbp),
        .csr_cfg_hact(csr_cfg_hact),
        .csr_cfg_fbytes(csr_cfg_fbytes),
        .csr_cfg_mindrv(csr_cfg_mindrv),
        .csr_cfg_b2wframe(csr_cfg_b2wframe),
        .csr_cfg_w2bframe(csr_cfg_w2bframe),
        .csr_cfg_fastg_b2gframe(csr_cfg_fastg_b2gframe),
        .csr_cfg_fastg_w2gframe(csr_cfg_fastg_w2gframe),
        .csr_mirror_en(csr_mirror_en),
        .csr_blank_input(csr_blank_input),
        .csr_input_ctrl(csr_input_ctrl),
        .sys_ready(1'b1),
        .mig_error(1'b0),
        .mif_error(1'b0),
        .op_busy(1'b0),
        .op_queue(1'b0),
        .csr_damage_counter(21'h1abcd),
        .input_status(8'ha5),
        .input_meas_hact(12'h678),
        .input_meas_vact(12'h345),
        .input_meas_htotal(12'habc),
        .input_meas_vtotal(12'hdef),
        .debug_memif_state(8'h5a),
        .debug_fifo_state(8'hc3),
        .dbg_spi_req_wen(dbg_spi_req_wen),
        .dbg_spi_req_addr(dbg_spi_req_addr),
        .dbg_spi_req_wdata(dbg_spi_req_wdata)
    );

    task fail;
        input [511:0] message;
        begin
            $display("FAIL: %0s at time %0t", message, $time);
            $fatal(1);
        end
    endtask

    task expect8;
        input [7:0] actual;
        input [7:0] expected;
        input [511:0] message;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s expected 0x%02x got 0x%02x at time %0t",
                    message, expected, actual, $time);
                $fatal(1);
            end
        end
    endtask

    task spi_transfer;
        input [7:0] tx;
        output [7:0] rx;
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                spi_mosi = tx[i];
                spi_sck = 1'b0;
                repeat (2) @(posedge clk);
                spi_sck = 1'b1;
                repeat (2) @(posedge clk);
                rx[i] = spi_miso;
            end
        end
    endtask

    task spi_read_reg8;
        input [7:0] addr;
        output [7:0] value;
        reg [7:0] ignored;
        begin
            spi_cs = 1'b0;
            spi_transfer(addr, ignored);
            repeat (2) @(posedge clk);
            spi_transfer(8'h00, value);
            spi_cs = 1'b1;
            spi_sck = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    task spi_write_reg8;
        input [7:0] addr;
        input [7:0] value;
        reg [7:0] ignored;
        begin
            spi_cs = 1'b0;
            spi_transfer(addr, ignored);
            repeat (2) @(posedge clk);
            spi_transfer(value, ignored);
            spi_cs = 1'b1;
            spi_sck = 1'b1;
            repeat (2) @(posedge clk);
        end
    endtask

    reg [7:0] read_value;

    initial begin
        $dumpfile("csr_tb.vcd");
        $dumpvars(0, csr_tb);

        rst = 1'b1;
        spi_cs = 1'b1;
        spi_sck = 1'b1;
        spi_mosi = 1'b0;
        repeat (4) @(posedge clk);
        rst = 1'b0;
        repeat (4) @(posedge clk);

        spi_read_reg8(`CSR_ID0, read_value);
        expect8(read_value, 8'h35, "CSR_ID0 readback");

        spi_read_reg8(`CSR_DAMAGE_COUNT_HI, read_value);
        expect8(read_value, 8'h01, "damage counter high byte readback");
        spi_read_reg8(`CSR_DAMAGE_COUNT_MID, read_value);
        expect8(read_value, 8'hab, "damage counter middle byte readback");
        spi_read_reg8(`CSR_DAMAGE_COUNT_LO, read_value);
        expect8(read_value, 8'hcd, "damage counter low byte readback");

        if (csr_input_ctrl !== 8'h01) begin
            fail("input control reset defaults to forced internal");
        end
        spi_write_reg8(`CSR_INPUT_CTRL, 8'h0a);
        if (csr_input_ctrl !== 8'h0a) begin
            fail("input control write");
        end

        spi_read_reg8(`CSR_INPUT_STATUS, read_value);
        expect8(read_value, 8'ha5, "input status readback");
        spi_read_reg8(`CSR_INPUT_MEAS_HACT_HI, read_value);
        expect8(read_value, 8'h06, "input measured hact high");
        spi_read_reg8(`CSR_INPUT_MEAS_HACT_LO, read_value);
        expect8(read_value, 8'h78, "input measured hact low");
        spi_read_reg8(`CSR_INPUT_MEAS_VACT_HI, read_value);
        expect8(read_value, 8'h03, "input measured vact high");
        spi_read_reg8(`CSR_INPUT_MEAS_VACT_LO, read_value);
        expect8(read_value, 8'h45, "input measured vact low");
        spi_read_reg8(`CSR_INPUT_MEAS_HTOT_HI, read_value);
        expect8(read_value, 8'h0a, "input measured htotal high");
        spi_read_reg8(`CSR_INPUT_MEAS_HTOT_LO, read_value);
        expect8(read_value, 8'hbc, "input measured htotal low");
        spi_read_reg8(`CSR_INPUT_MEAS_VTOT_HI, read_value);
        expect8(read_value, 8'h0d, "input measured vtotal high");
        spi_read_reg8(`CSR_INPUT_MEAS_VTOT_LO, read_value);
        expect8(read_value, 8'hef, "input measured vtotal low");
        spi_read_reg8(`CSR_DEBUG_MEMIF_STATE, read_value);
        expect8(read_value, 8'h5a, "memif debug state readback");
        spi_read_reg8(`CSR_DEBUG_FIFO_STATE, read_value);
        expect8(read_value, 8'hc3, "fifo debug state readback");

        spi_write_reg8(`CSR_OSD_ADDR_HI, 8'h1f);
        spi_write_reg8(`CSR_OSD_ADDR_LO, 8'hff);
        if (csr_osd_addr !== 13'h1fff) begin
            fail("13-bit OSD address write");
        end

        if (csr_osd_scale_2x !== 1'b0) begin
            fail("OSD scale reset default");
        end
        spi_write_reg8(`CSR_OSD_SCALE, 8'h01);
        if (csr_osd_scale_2x !== 1'b1) begin
            fail("OSD scale write one");
        end
        spi_write_reg8(`CSR_OSD_SCALE, 8'h02);
        if (csr_osd_scale_2x !== 1'b0) begin
            fail("OSD scale write uses bit zero");
        end

        spi_write_reg8(`CSR_TONE_ADDR, 8'h10);
        spi_write_reg8(`CSR_TONE_WR, 8'ha5);
        if (csr_tone_wr !== 8'ha5) begin
            fail("tone LUT write data");
        end
        if (csr_tone_we !== 1'b0) begin
            fail("tone LUT write enable clears");
        end
        if (csr_tone_addr !== 8'h11) begin
            fail("tone LUT address auto-increment");
        end

        $display("csr_tb completed at time %0t", $time);
        $finish;
    end

endmodule
`default_nettype wire
