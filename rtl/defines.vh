
`define OP_INIT             2'd0 // Initial power up
`define OP_NORMAL           2'd1 // Normal operation

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
