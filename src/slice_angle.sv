`timescale 1ns / 1ps
`default_nettype none

module slice_angle(
	input wire pixel_clk_in,
  	input wire rst_in,

	input wire [10:0] hcount_in,
  	input wire [9:0] vcount_in,
  	input wire [10:0] katana_x,
  	input wire [9:0] katana_y,

  	output real angle
);

	// IMPORTANT: when h_count == 1024 and v_count == 768, frame is over
  	logic frame_done;
  	assign frame_done = hcount_in == 1024 && vcount_in == 768;

	// buffer in 10 x,y coordinates every frame
	logic [10:0] x_buffer [9:0];
	logic [9:0] y_buffer [9:0];

	logic [7:0] rise;
	logic [7:0] run;

	always_comb begin // calculating rise and run
		rise = y_buffer[0] - y_buffer[9];
		run = x_buffer[0] - x_buffer[9];
	end

	always_ff @(posedge pixel_clk_in)begin
		if(rst_in) begin
			for(int i = 0; i <= 9; i=i+1) begin //clear buffers
				x_buffer[i] <= 0;
				y_buffer[i] <= 0;
			end
		end else begin
			if (frame_done) begin
				x_buffer[0] <= katana_x; // shifting buffer items
				y_buffer[0] <= katana_y;
				for(int i = 1; i <= 9; i=i+1) begin
					x_buffer[i] <= x_buffer[i-1];
					y_buffer[i] <= y_buffer[i-1];
				end
			end

			angle <= $atan2(run,rise); // calculating angle in radians

		end
	end

endmodule

`default_nettype wire