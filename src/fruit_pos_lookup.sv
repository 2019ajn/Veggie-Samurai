`timescale 1ns / 1ps
`default_nettype none

module fruit_pos_lookup (
    input wire clk_in,
    input wire rst_in,
    input wire [15:0] random_in,
    output logic [10:0] x_start,
    output logic [2:0] x_vel_out,
    output logic [4:0] y_vel_out,
    output logic x_direction_neg
);
// 2 bits for x_vel
// 4 bits for y vel out
// 1 bit for x direction
logic [1:0] x_vel_bits;
logic [1:0] y_vel_bits;
logic [6:0] rando_move;
assign x_vel_bits = random_in[2:1];
assign y_vel_bits = random_in[4:3];
assign rando_move = random_in[11:5];

always_comb begin
    x_direction_neg = random_in[0];
    case (x_vel_bits) 
        2'b00: x_vel_out = 3'd1;
        2'b01: x_vel_out = 3'd2;
        2'b10: x_vel_out = 3'd3;
        default: x_vel_out = 3'd4;
    endcase
    case (y_vel_bits)
        //2'b00: y_vel_out = 4'd8;
        2'b01: y_vel_out = 4'd10;
        2'b10: y_vel_out = 4'd14;
        default: y_vel_out = 4'd12;
    endcase
    if (x_direction_neg) begin
        x_start = 350 + rando_move;
    end else begin
        x_start = 256 - rando_move;
    end
end


endmodule
`default_nettype wire