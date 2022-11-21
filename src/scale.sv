`timescale 1ns / 1ps
`default_nettype none

module scale(
  input wire [1:0] scale_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [15:0] frame_buff_in,
  output logic [15:0] cam_out
);
  //YOUR DESIGN HERE!

logic [10:0] width;
logic [9:0] height;
logic in_frame;

assign in_frame = ((hcount_in < width) && (vcount_in < height));

assign cam_out = in_frame ? frame_buff_in : 16'b0000;

  always_comb begin
    if (scale_in == 2'b00) begin // 1x scale
      width = 240;
      height = 320;
    end else if (scale_in == 2'b01) begin // 2x scale
      width = 480;
      height = 640;
    end else if (scale_in == 2'b10) begin // 8/3x scale
      width = 640;
      height = 853;
    end
  end
endmodule
`default_nettype wire
