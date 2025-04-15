module line_reverse(
    input wire clk,
    input wire rst,
    input wire [15:0] pix_in,
    input wire pix_in_en,
    output reg [15:0] pix_out,
    output reg pix_out_en
);

    parameter WIDTH = 1200; // In cycles
    //parameter BUFDEPTH = $clog2(WIDTH);
    parameter BUFDEPTH = 11;

    reg wr_buffer;
    wire rd_buffer = !wr_buffer;
    reg buf0_valid;
    reg buf1_valid;
    wire rd_buffer_valid = (rd_buffer) ? buf1_valid : buf0_valid;

    reg [15:0] buf0 [0:WIDTH-1];
    reg [15:0] buf1 [0:WIDTH-1];
    reg [BUFDEPTH-1:0] rdptr;
    reg [BUFDEPTH-1:0] wrptr;
    
    wire [15:0] pix_in_r = {pix_in[7:0], pix_in[15:8]};

    always @(posedge clk) begin
        // WR
        if (pix_in_en) begin
            if (wr_buffer)
                buf1[wrptr] <= pix_in_r;
            else
                buf0[wrptr] <= pix_in_r;
            wrptr <= wrptr + 'd1;
            if (wrptr == WIDTH - 1) begin
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
            pix_out_en <= 1'b1;
            if (rd_buffer)
                pix_out <= buf1[rdptr];
            else
                pix_out <= buf0[rdptr];
            rdptr <= rdptr - 'd1;
            if (rdptr == 'd0) begin
                rdptr <= WIDTH - 1;
                if (rd_buffer) begin
                    buf1_valid <= 'd0;
                end
                else begin
                    buf0_valid <= 'd0;
                end
            end
        end
        else begin
            pix_out_en <= 1'b0;
        end

        if (rst) begin
            rdptr <= WIDTH-1;
            wrptr <= 'd0;
            wr_buffer <= 1'b0;
            buf0_valid <= 1'b0;
            buf1_valid <= 1'b0;
            pix_out_en <= 1'b1;
        end
    end

endmodule
