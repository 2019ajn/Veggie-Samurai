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

	logic [10:0] veggie_width; // need to be assigned
	logic [9:0] veggie_height; // need to be assigned
	logic [10:0] top_veggie_x;
	logic [9:0] top_veggie_y;
	logic [11:0] top_veggie_out; // top_veggie pixel_out from split_image module
	logic [10:0] bottom_veggie_x;
	logic [9:0] bottom_veggie_y;
	logic [11:0] bottom_veggie_out; // bottom_veggie pixel_out from split_image module

	logic [2:0] top_veggie_x_speed;
	logic [2:0] top_veggie_y_speed;
	logic [2:0] bottom_veggie_x_speed;
	logic [2:0] bottom_veggie_y_speed;

	logic [11:0] katana_out; // katana pixel_out from split_image module

	logic split;

	// instantiate veggie and katana split_sprite here
	// don't need split signal for katana
	//
	// split_sprite #(parameters) top_veggie(
	//		.x_in(top_veggie_x), .hcount_in(hcount_in),
	// 		.y_in(top_veggie_y), .vcount_in(vcount_in),
	//		.split_in(split), .pixel_out(top_veggie_out));
	//
	// split_sprite #(parameters) bottom_veggie(
	//		.x_in(bottom_veggie_x), .hcount_in(hcount_in),
	// 		.y_in(bottom_veggie_y), .vcount_in(vcount_in),
	//		.split_in(split), .pixel_out(bottom_veggie_out));
	//
	// split_sprite #(parameters) katana(
	//		.x_in(katana_x), .hcount_in(hcount_in),
	// 		.y_in(katana_y), .vcount_in(vcount_in),
	//		.split_in(), .pixel_out(katana_out));

	// instantiate veggie parabolic movement module outputs x and y speed
	// upon receiving split signal, change movement
	// parabolic movement(
	// 		.clk_in(pixel_clk_in), .rst_in(rst_in),
	//		.split_in(split), 
	//		.x_speed_out(top_veggie_x_speed), .y_speed_out(top_veggie_y_speed));


	// IMPORTANT: when h_count == 1024 and v_count == 768, frame is over
  	logic frame_done;
  	assign frame_done = hcount_in == 1024 && vcount_in == 768;


	always_comb begin // katana displays "on top of" fruit
		if (|katana_out) begin
			pixel_out = katana_out;
		end else if (|fruit_out) begin
			pixel_out = top_fruit_out;
		end else if (|bottom_fruit_out) begin
			pixel_out = bottom_fruit_out;
		end
	end

	always_ff @(posedge pixel_clk_in) begin
		if(rst_in) begin // starting positions for fruit and katana
			split <= 0;
		end else begin
			split <= 0; // ensures split is only up for one clock cycle
			if (frame_done) begin // finished current frame, logic for next frame

				// VEGGIE MOVEMENT
				top_veggie_x <= top_veggie_x + (4*top_veggie_x_speed); // top veggie horizontal movement
      			top_veggie_y <= top_veggie_y + (4*top_veggie_y_speed); // top veggie vertical movement
      			bottom_veggie_x <= bottom_veggie_x + (4*bottom_veggie_x_speed); // top veggie horizontal movement
      			bottom_veggie_y <= bottom_veggie_y + (4*bottom_veggie_y_speed); // top veggie vertical movement
				
				// KATANA-VEGGIE INTERACTION - if katana contacts fruit, send split signal for one clock cycle;
				if (~split) begin // make sure split signal is only sent when fruit isn't already split
					if ((katana_x >= top_fruit_x && katana_x <= top_fruit_x - fruit_width) &&
					(katana_y >= top_fruit_y && katana_y <= top_fruit_y - fruit_height)) begin
						split <= 1;
					end
				end

				// VEGGIE RESPAWN
				// need a randomized respawn point at the bottom of the screen whenever split veggies hit the bottom


			end
		end
	end


endmodule

`default_nettype wire