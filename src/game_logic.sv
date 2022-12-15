`timescale 1ns / 1ps
`default_nettype none

module game_logic(
	input wire clk_in,
 	input wire rst_in,

  	input wire [10:0] hcount_in,
  	input wire [9:0] vcount_in,
  	input wire [10:0] katana_x,
  	input wire [9:0] katana_y,

  	output logic [11:0] pixel_out
	);

	logic [10:0] veggie_width; // need to be assigned
	logic [9:0] veggie_height; // need to be assigned

	logic [10:0] veggie_x;
	logic [9:0] veggie_y;

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

	logic signed [10:0] run;
	logic signed [9:0] rise;

	logic split;
	logic un_split;

	//logic veggie_gone; // when parabolic motion module receives veggie_gone, set movement to zero
					   // when split_sprite module receives veggie_gone, make veggie disappear

	logic up;

	logic [15:0] random; // random 16-bit number

	slice_angle katana (
  		.clk_in(clk_in),
  		.rst_in(rst_in),
  		.hcount_in(hcount_in), // need to be pipelined?
  		.vcount_in(vcount_in), // need to be pipelined?
  		.katana_x(katana_x), // from tracking/CoM
  		.katana_y(katana_y), // from tracking/CoM
  		.split_in(split),
  		.rise(rise), // goes to split_sprite
  		.run(run) // goes to split_sprite
	);

	// instantiate veggie and katana split_sprite here
	// don't need split, angle, or veggie_gone signals for katana

	//assign top_veggie_x = 200;
	//assign top_veggie_y = 200;
	//assign bottom_veggie_x = 400;
	//assign bottom_veggie_y = 400;
	
	split_sprite #(.WIDTH(128), .HEIGHT(128)) top_veggie(
			.pixel_clk_in(clk_in), .rst_in(rst_in),
			.x_in(top_veggie_x), .hcount_in(hcount_in),
	 		.y_in(top_veggie_y), .vcount_in(vcount_in),
			.split_in(split), .rise(rise), .run(run),
			.is_top(1), .veggie_gone_in(),
			.pixel_out(top_veggie_out));
	
	/*
	split_sprite #(.WIDTH(128), .HEIGHT(128)) bottom_veggie(
			.pixel_clk_in(clk_in), .rst_in(rst_in),
			.x_in(bottom_veggie_x), .hcount_in(hcount_in),
	 		.y_in(bottom_veggie_y), .vcount_in(vcount_in),
			.split_in(split), .rise(rise), .run(run),
			.is_top(0), .veggie_gone_in(),
			.pixel_out(bottom_veggie_out));
	*/

	//block sprites for testing
	/*
	block_sprite #(.WIDTH(128), .HEIGHT(128), .COLOR(12'h00F)) top_veggie(
            .x_in(top_veggie_x), .hcount_in(hcount_in),
            .y_in(top_veggie_y), .vcount_in(vcount_in),
            .pixel_out(top_veggie_out));
	block_sprite #(.WIDTH(128), .HEIGHT(128), .COLOR(12'h00F)) bottom_veggie(
            .x_in(bottom_veggie_x), .hcount_in(hcount_in),
            .y_in(bottom_veggie_y), .vcount_in(vcount_in),
            .pixel_out(bottom_veggie_out));
    */

    lfsr_16 yuh(.clk_in(clk_in), // LFSR "RANDOMIZER"
              .rst_in(0),
              .seed_in(16'b1),
              .q_out(random)); // random 16-bit number
    
	// instantiate veggie parabolic movement module outputs x and y speed
	// upon receiving split signal, change movement
	// upon receiving veggie_gone signal, set movement to zero
	
	parabolic movement(
			.clk_in(clk_in), .rst_in(rst_in),
			.random(random),
			.hcount(hcount_in), .vcount(vcount_in),
			.new_x(veggie_x), .new_y(veggie_y),
			.un_split(un_split));


	// IMPORTANT: when h_count == 1024 and v_count == 768, frame is over
  	logic frame_done;
  	assign frame_done = hcount_in == 1024 && vcount_in == 768;

	always_comb begin // katana displays "on top of" fruit
		if (|top_veggie_out) begin
			pixel_out = top_veggie_out;
		end else if (|bottom_veggie_out) begin
			pixel_out = bottom_veggie_out;
		end
	end

	always_ff @(posedge clk_in) begin
		if(rst_in) begin // starting positions for fruit and katana
			split <= 0;
		end else begin
			if (frame_done) begin // finished current frame, logic for next frame
				top_veggie_x <= veggie_x;
				top_veggie_y <= veggie_y;
				bottom_veggie_x <= veggie_x;
				bottom_veggie_y <= veggie_y;

				// VEGGIE MOVEMENT
				/*
				if (split) begin
					top_veggie_x <= veggie_x + 100;
					top_veggie_y <= veggie_y;
					bottom_veggie_x <= veggie_x - 100;
					bottom_veggie_y <= veggie_y;
				end else begin
					top_veggie_x <= veggie_x;
					top_veggie_y <= veggie_y;
					bottom_veggie_x <= veggie_x;
					bottom_veggie_y <= veggie_y;
				end */

				//top_veggie_x <= top_veggie_x + (4*top_veggie_x_speed); // top veggie horizontal movement
      			//top_veggie_y <= top_veggie_y + (4*top_veggie_y_speed); // top veggie vertical movement
      			//bottom_veggie_x <= bottom_veggie_x + (4*bottom_veggie_x_speed); // top veggie horizontal movement
      			//bottom_veggie_y <= bottom_veggie_y + (4*bottom_veggie_y_speed); // top veggie vertical movement
				
				// KATANA-VEGGIE INTERACTION - if katana contacts fruit, send split signal for one clock cycle;
				
				//if (~split) begin // make sure split signal is only sent when fruit isn't already split
					if ((katana_x >= veggie_x - 64 && katana_x <= veggie_x + 64) &&
					(katana_y >= veggie_y - 64 && katana_y <= veggie_y + 64)) begin
						split <= 1;
					end
				//end
				

				if (un_split) begin
					split <= 0;
				end
				

				// VEGGIE RESPAWN (when veggie hits bottom - doesn't matter if sliced or not)
				// need a randomized respawn point at the bottom of the screen whenever split veggies hit the bottom
				/*
				if (top_veggie_y > 768-veggie_height-12) begin // need to account for vertical speed. If veggie is moving at 12 pixels per frame, bound needs to make sure it can't "jump past"
					split <= 0; // unsplit
					veggie_gone <= 1;
					// set new starting point here using randomizer
				end
				*/
			end
		end
	end


endmodule

`default_nettype wire