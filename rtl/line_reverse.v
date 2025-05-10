module line_reverse #(
    parameter BUFDEPTH = 11,
    parameter PIXWIDTH = 32
) (
    input wire clk,
    input wire rst,
    input wire [BUFDEPTH-1:0] width,
    input wire [PIXWIDTH-1:0] pix_in,
    input wire pix_in_en,
    input wire pix_out_ready,
    output reg [PIXWIDTH-1:0] pix_out,
    output reg pix_out_valid
);
    localparam MAXWIDTH = 1 << BUFDEPTH;
    reg wr_buffer;
    wire rd_buffer = !wr_buffer;
    reg buf0_valid;
    reg buf1_valid;
    wire rd_buffer_valid = (rd_buffer) ? buf1_valid : buf0_valid;

    reg [PIXWIDTH-1:0] buf0 [0:MAXWIDTH-1];
    reg [PIXWIDTH-1:0] buf1 [0:MAXWIDTH-1];
    reg [BUFDEPTH-1:0] rdptr;
    reg [BUFDEPTH-1:0] wrptr;
    
    wire [BUFDEPTH-1:0] rdptr_next = rdptr - 'd1;
    wire [BUFDEPTH-1:0] wrptr_next = wrptr + 'd1;
    wire [PIXWIDTH-1:0] pix_in_r;
    generate // Should have been a for loop
        if (PIXWIDTH == 16) begin
            assign pix_in_r = {pix_in[7:0], pix_in[15:8]};
        end else if (PIXWIDTH == 32) begin
            assign pix_in_r = {pix_in[7:0], pix_in[15:8], pix_in[23:16], pix_in[31:24]};
        end
    endgenerate

    always @(posedge clk) begin
        // WR
        if (pix_in_en) begin
            if (wr_buffer)
                buf1[wrptr] <= pix_in_r;
            else
                buf0[wrptr] <= pix_in_r;
            wrptr <= wrptr_next;
            if (wrptr_next == width) begin
                wrptr <= 'd0;
                if (wr_buffer) begin
                    buf1_valid <= 'd1;
                end
                else begin
                    buf0_valid <= 'd1;
                end
                wr_buffer <= ~wr_buffer;
            end
        end
        
        // RD
        if (rd_buffer_valid) begin
            pix_out_valid <= 1'b1;
            if (rd_buffer)
                pix_out <= buf1[rdptr_next];
            else
                pix_out <= buf0[rdptr_next];
            if (pix_out_valid && pix_out_ready)
                rdptr <= rdptr_next;

            if (rdptr_next == 'd0) begin
                rdptr <= width;
                if (rd_buffer) begin
                    buf1_valid <= 'd0;
                end
                else begin
                    buf0_valid <= 'd0;
                end
            end
        end
        else begin
            pix_out_valid <= 1'b0;
        end

        if (rst) begin
            rdptr <= width;
            wrptr <= 'd0;
            wr_buffer <= 1'b0;
            buf0_valid <= 1'b0;
            buf1_valid <= 1'b0;
            pix_out_valid <= 1'b0;
        end
    end

endmodule
