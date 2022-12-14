`timescale 1ns / 1ps
`default_nettype none

module slice_angle(
	input wire clk_in,
  	input wire rst_in,

	input wire [10:0] hcount_in,
  	input wire [9:0] vcount_in,
  	input wire [10:0] katana_x,
  	input wire [9:0] katana_y,
  	input wire split_in,

  	output logic signed [9:0] rise,
  	output logic signed [9:0] run
);

	// IMPORTANT: when h_count == 1024 and v_count == 768, frame is over
  	logic frame_done;
  	assign frame_done = hcount_in == 1024 && vcount_in == 768;

	// buffer in 10 x,y coordinates every frame
	logic [10:0] x_buffer [9:0];
	logic [9:0] y_buffer [9:0];

	// possibly output rise/run and make sure they're signed (from lab 4b)

	always @(*) begin // calculating rise and run
		if (~split_in) begin // only change rise and run if not split yet. if split, hold values.
			rise = $signed({1'b0,y_buffer[0]} - {1'b0,y_buffer[9]});
			run = $signed({1'b0,x_buffer[0]} - {1'b0,x_buffer[9]});
		end
	end



	always_ff @(posedge clk_in)begin
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


		end
	end

endmodule

`default_nettype wire