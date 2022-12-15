`timescale 1ns / 1ps
`default_nettype none

module parabolic(
    input wire clk_in,
    input wire rst_in,
    input wire [15:0] random,
    input wire [10:0] hcount,
    input wire [9:0] vcount,
    output logic [10:0] new_x,
    output logic [9:0] new_y,
    output logic un_split
);
logic frame_done;
assign frame_done = hcount == 1024 && vcount == 768;
logic [3:0] cycle_counter;

logic [4:0] y_speed;
logic [2:0] x_speed;

logic x_direction_neg;
logic y_direction_neg;
logic gone;

logic [10:0] initial_x;
logic [9:0] initial_y;
logic initial_x_dir;
logic [4:0] initial_y_vel;
logic [2:0] initial_x_vel;
fruit_pos_lookup fruit_motion(.clk_in(clk_in), 
                                .rst_in(rst_in), 
                                .random_in(random), 
                                .x_start(initial_x), 
                                .x_vel_out(initial_x_vel), 
                                .y_vel_out(initial_y_vel),
                                .x_direction_neg(initial_x_dir));

always_ff @(posedge clk_in) begin
    if (rst_in || gone) begin
        cycle_counter <= 0;
        new_x <= initial_x;
        new_y <= 700;
        x_direction_neg <= initial_x_vel;
        y_direction_neg <= 0;
        y_speed <= initial_y_vel;
        x_speed <= initial_x_vel;
        gone <= 0;
        un_split <= 0;
        
    end else begin
        if (frame_done) begin
            // updating cycle counter for when to use gravity effect
            if (cycle_counter == 10) begin
                cycle_counter <= 0;
                if (!y_direction_neg) begin
                    if (y_speed == 2) begin
                    y_direction_neg <= 1'b1;
                    end
                    y_speed <= y_speed - 2;
                end else begin
                    y_speed <= y_speed + 2;
                end
            end else begin
                cycle_counter <= cycle_counter + 1;
            end

            x_speed <= x_speed;

            if (y_direction_neg) begin
                if (new_y + y_speed < 704) begin
                    new_y <= new_y + y_speed;
                end else begin
                    gone <= 1;
                    un_split <= 1;
                end 
            end else begin
                if (new_y > 16) begin
                    new_y <= new_y - y_speed;
                end else begin
                    gone <= 1;
                    un_split <= 1;
                end
            end
        

            if (x_direction_neg) begin
                if (new_x - x_speed > 0) begin
                    new_x <= new_x - x_speed;
                end else
                    gone <= 1;
                    un_split <= 1;
            end else begin
                if (new_x + x_speed < 640) begin
                    new_x <= new_x + x_speed;
                end else
                    gone <= 1;
                    un_split <= 1;
            end
        end
    end
end

endmodule
`default_nettype wire