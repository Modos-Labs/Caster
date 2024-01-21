
`define OP_INIT             2'd0 // Initial power up
`define OP_NORMAL           2'd1 // Normal operation

// CSR map
`define CSR_LUT_FRAME       8'd0
`define CSR_LUT_ADDR_HI     8'd1
`define CSR_LUT_ADDR_LO     8'd2
`define CSR_LUT_WR          8'd3
`define CSR_OP_LEFT_HI      8'd4
`define CSR_OP_LEFT_LO      8'd5
`define CSR_OP_RIGHT_HI     8'd6
`define CSR_OP_RIGHT_LO     8'd7
`define CSR_OP_TOP_HI       8'd8
`define CSR_OP_TOP_LO       8'd9
`define CSR_OP_BOTTOM_HI    8'd10
`define CSR_OP_BOTTOM_LO    8'd11
`define CSR_OP_PARAM        8'd12
`define CSR_OP_LENGTH       8'd13
`define CSR_OP_CMD          8'd14
`define CSR_CONTROL         8'd15
`define CSR_CFG_V_FP        8'd16
`define CSR_CFG_V_SYNC      8'd17
`define CSR_CFG_V_BP        8'd18
`define CSR_CFG_V_ACT_HI    8'd19
`define CSR_CFG_V_ACT_LO    8'd20
`define CSR_CFG_H_FP        8'd21
`define CSR_CFG_H_SYNC      8'd22
`define CSR_CFG_H_BP        8'd23
`define CSR_CFG_H_ACT_HI    8'd24
`define CSR_CFG_H_ACT_LO    8'd25
`define CSR_CFG_FBYTES_B2   8'd27
`define CSR_CFG_FBYTES_B1   8'd28
`define CSR_CFG_FBYTES_B0   8'd29

// FB operations
// Redraw:
// In fast bw/ gray mode, the display input is forced to be black/ white
// during the clearing process.
// In GC16 mode, input is kept as is, but screen update is forced
`define OP_EXT_REDRAW       8'd0
// Set mode: set a specified region to a display mode by refershing the
// image to white first in frames specified in op_param, then set to the
// target update mode. The refreshing to white part is skipped if op_param
// is set to 0.
`define OP_EXT_SETMODE      8'd1

`define SETMODE_MANUAL_LUT_NO_DITHER       8'd0
`define SETMODE_MANUAL_LUT_ERROR_DIFFUSION 8'd1
`define SETMODE_FAST_MONO_NO_DITHER        8'd2
`define SETMODE_FAST_MONO_ORDERED          8'd3
`define SETMODE_FAST_MONO_ERROR_DIFFUSION  8'd4
`define SETMODE_FAST_GREY                  8'd5
`define SETMODE_AUTO_LUT_NO_DITHER         8'd6
`define SETMODE_AUTO_LUT_ERROR_DIFFUSION   8'd7

// Define this to enable operation by default after reset
// Used for debugging purpose only
`define CSR_SELFBOOT

// `define DEFAULT_VFP         8'd45
// `define DEFAULT_VSYNC       8'd1
// `define DEFAULT_VBP         8'd2
// `define DEFAULT_VACT        12'd1200
// `define DEFAULT_HFP         8'd16
// `define DEFAULT_HSYNC       8'd2
// `define DEFAULT_HBP         8'd2
// `define DEFAULT_HACT        12'd400
`define DEFAULT_VFP         8'd12
`define DEFAULT_VSYNC       8'd1
`define DEFAULT_VBP         8'd3
`define DEFAULT_VACT        12'd758
`define DEFAULT_HFP         8'd72
`define DEFAULT_HSYNC       8'd2
`define DEFAULT_HBP         8'd2
`define DEFAULT_HACT        12'd256
`define DEFAULT_FBYTES      `DEFAULT_HACT * 4 * `DEFAULT_VACT * 2
