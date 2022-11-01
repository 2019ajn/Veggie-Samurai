`timescale 1ns / 1ps
`default_nettype none

module game_logic(
	input wire pixel_clk_in,
 	input wire rst_in,

  	input wire [10:0] hcount_in,
  	input wire [9:0]  vcount_in,
  	input wire [10:0] katana_x,
  	input wire [9:0] katana_y,

  	output logic [11:0] pixel_out
	);




endmodule

`default_nettype wire