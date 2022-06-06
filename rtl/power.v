module power(
    // Clock and reset
    // Runs at 33MHz clock
    input wire clk,
    input wire rst,
    // Control
    input wire en,
    input wire cen,
    output reg pok,
    output reg error, // I2C error, not power fault
    // I2C to PMIC
    inout wire i2c_sda,
    output wire i2c_scl,
    // debug
    output wire [2:0] dbg_state
);

    // TODO: Allow adjustable VCOM
    localparam VCOM_VAL = 8'd143; // -0.5 - 1.43 = -1.93V
    localparam I2C_ADDR = 7'h48;

    reg i2c_rw;
    reg [7:0] i2c_subaddr;
    reg [7:0] i2c_wrdata;
    wire [7:0] i2c_rddata;
    reg i2c_req;
    wire i2c_valid;
    wire i2c_busy;
    wire i2c_nack;

    i2c_master i2c_master(
        .i_clk(clk),
        .reset_n(!rst),
        .i_addr_w_rw({I2C_ADDR, i2c_rw}),
        .i_sub_addr({8'd0, i2c_subaddr}),
        .i_sub_len(1'b0),
        .i_byte_len(24'd1),
        .i_data_write(i2c_wrdata),
        .req_trans(i2c_req),
        .data_out(i2c_rddata),
        .valid_out(i2c_valid),
        .scl_o(i2c_scl),
        .sda_o(i2c_sda),
        .req_data_chunk(),
        .busy(i2c_busy),
        .nack(i2c_nack));

    localparam ST_IDLE = 3'd0;
    localparam ST_INIT = 3'd1;
    localparam ST_WAIT1 = 3'd2;
    localparam ST_WAIT2 = 3'd3;
    localparam ST_UPDATE_POK1 = 3'd4;
    localparam ST_UPDATE_POK2 = 3'd5;
    localparam ST_ERROR = 3'd6;

    reg [2:0] state;
    wire [1:0] cen_en = {cen, en};
    reg [1:0] last_cen_en;
    // checks pok every 22bit=4M cycles, rougly 120ms
    reg [21:0] idle_counter; 

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_INIT;
            i2c_rw <= 1'b0;
            i2c_subaddr <= 8'd0;
            i2c_wrdata <= 8'd0;
            i2c_req <= 1'b0;
            pok <= 1'b0;
            error <= 1'b0;
            last_cen_en <= 2'b0;
            idle_counter <= 0;
        end
        else begin
            case (state)
            ST_IDLE: begin
                if (last_cen_en != cen_en) begin
                    last_cen_en <= cen_en;
                    i2c_rw <= 1'b0;
                    i2c_subaddr <= 8'h09;
                    i2c_wrdata <= {6'd0, cen_en};
                    i2c_req <= 1'b1;
                    state <= ST_WAIT1;
                end
                else if (idle_counter == 0) begin
                    i2c_rw <= 1'b1;
                    i2c_subaddr <= 8'h0a;
                    i2c_req <= 1'b1;
                    state <= ST_UPDATE_POK1;
                    idle_counter <= idle_counter + 1;
                end
                else begin
                    idle_counter <= idle_counter + 1;
                end
            end
            ST_INIT: begin
                i2c_rw <= 1'b0; // Write
                i2c_subaddr <= 8'h08; // DVR register
                i2c_wrdata <= VCOM_VAL;
                i2c_req <= 1'b1;
                state <= ST_WAIT1;
            end
            ST_WAIT1: begin
                i2c_req <= 1'b0;
                state <= ST_WAIT2;
            end
            ST_WAIT2: begin
                if (i2c_nack) begin
                    error <= 1'b1;
                    state <= ST_ERROR;
                end
                else if (!i2c_busy) begin
                    state <= ST_IDLE;
                end
            end
            ST_UPDATE_POK1: begin
                i2c_req <= 1'b0;
                state <= ST_UPDATE_POK2;
            end
            ST_UPDATE_POK2: begin
                if (i2c_nack) begin
                    error <= 1'b1;
                    state <= ST_ERROR;
                end
                else if (!i2c_busy) begin
                    pok <= i2c_rddata[7];
                    state <= ST_IDLE;
                end
            end
            ST_ERROR: begin
                // Nothing, wait to be resetted
            end
            endcase
        end
    end
    
    assign dbg_state = state;
                
endmodule
