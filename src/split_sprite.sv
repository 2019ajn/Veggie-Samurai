`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module split_sprite #(parameter WIDTH=256, HEIGHT=256) (
    input wire pixel_clk_in,
    input wire rst_in,
    input wire [10:0] x_in, hcount_in,
    input wire [9:0]  y_in, vcount_in,
    input wire split_in,
    input wire signed[10:0] run,
    input wire signed[9:0] rise,
    input wire veggie_gone_in,
    input wire is_top,
    output logic [11:0] pixel_out);


    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8),                       // Specify RAM data width
        .RAM_DEPTH(256*256),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(banana_image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) image (
        .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
        .dina(0),       // RAM input data, width determined from RAM_WIDTH
        .clka(pixel_clk_in),       // Clock
        .wea(0),         // Write enable
        .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst_in),       // Output reset (does not affect memory contents)
        .regcea(1),   // Output register enable
        .douta(image_out)      // RAM output data, width determined from RAM_WIDTH
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(12),                       // Specify RAM data width
        .RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
        .INIT_FILE(`FPATH(banana_palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
    ) palette (
        .addra(image_out),     // Address bus, width determined from RAM_DEPTH
        .dina(0),       // RAM input data, width determined from RAM_WIDTH
        .clka(pixel_clk_in),       // Clock
        .wea(0),         // Write enable
        .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
        .rsta(rst_in),       // Output reset (does not affect memory contents)
        .regcea(1),   // Output register enable
        .douta(palette_out)      // RAM output data, width determined from RAM_WIDTH
    );

    logic [7:0] image_out;
    logic [11:0] palette_out;

    // calculate rom address
    logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
    //assign image_addr = (hcount_in - (x_in - WIDTH >> 1) + (vcount_in - (y_in - HEIGHT >> 1)) * WIDTH);
    assign image_addr = (hcount_in - x_in + 64) + ((vcount_in - y_in + 64) * WIDTH);


    // assigning in_sprite based on split line
    logic in_sprite;
    logic signed [3:0] test_run;
    logic signed [3:0] test_rise;

    assign test_run = 4'b0001;
    assign test_rise = 4'b0000;

    /*
    always_ff @(posedge pixel_clk_in) begin
        if (split_in) begin
            test_rise <= rise;
        end
    end */

    always_comb begin

        //slope needs to originate from center
        
        if (split_in) begin
            if (is_top) begin
                if (rise[3:0] == 0) begin
                    in_sprite = hcount_pipe[3] >= x_in - (WIDTH >> 1) && hcount_pipe[3] < x_in + (WIDTH >> 1) &&
                      vcount_pipe[3] >= y_in - (HEIGHT >> 1) && vcount_pipe[3] < y_in;
                end else if (run[3:0] == 0) begin
                    in_sprite = hcount_pipe[3] >= x_in - (WIDTH >> 1) && hcount_pipe[3] < x_in &&
                      vcount_pipe[3] >= y_in - (HEIGHT >> 1) && vcount_pipe[3] < y_in + (HEIGHT >> 1);
                end else begin
                    in_sprite = hcount_pipe[3] >= x_in - (WIDTH >> 1) && hcount_pipe[3] < x_in + (WIDTH >> 1) &&
                                vcount_pipe[3] >= y_in - (HEIGHT >> 1) && vcount_pipe[3] <= 64 - y_in + (hcount_pipe[3] - 64) * rise[3:0] / run[3:0] && vcount_pipe[3] <= y_in + (HEIGHT >> 1);
                end
            end else begin
                if (rise[3:0] == 0) begin
                    in_sprite = hcount_pipe[3] >= x_in - (WIDTH >> 1) && hcount_pipe[3] < x_in + (WIDTH >> 1) &&
                      vcount_pipe[3] >= y_in && vcount_pipe[3] < y_in + (HEIGHT >> 1);
                end else if (run[3:0] == 0) begin
                    in_sprite = hcount_pipe[3] >= x_in && hcount_pipe[3] < x_in + (WIDTH >> 1) &&
                      vcount_pipe[3] >= y_in - (HEIGHT >> 1) && vcount_pipe[3] < y_in;
                end else begin
                    in_sprite = hcount_pipe[3] >= x_in - (WIDTH >> 1) && hcount_pipe[3] < x_in + (WIDTH >> 1) &&
                                vcount_pipe[3] >= y_in - (HEIGHT >> 1) && vcount_pipe[3] > 64 - y_in + (hcount_pipe[3] - 64) * rise[3:0] / run[3:0] && vcount_pipe[3] <= y_in + (HEIGHT >> 1);
                end
                //in_sprite = hcount_pipe[3] >= x_in - (WIDTH >> 1) && hcount_pipe[3] < x_in + (WIDTH >> 1) &&
                //            vcount_pipe[3] >= y_in - (HEIGHT >> 1) && $signed({1'b0,vcount_pipe[3]}) > $signed({1'b0,(y_in - (HEIGHT >> 1))}) + $signed({1'b0,hcount_pipe[3]}) * $signed(test_rise[9:6]) / $signed(test_run[10:7]);
            end
        end else begin
            in_sprite = hcount_pipe[3] >= x_in - (WIDTH >> 1) && hcount_pipe[3] < x_in + (WIDTH >> 1) &&
                      vcount_pipe[3] >= y_in - (HEIGHT >> 1) && vcount_pipe[3] < y_in + (HEIGHT >> 1);
        end
    end
    
    

    // Modify the line below to use your BRAMs!
    assign pixel_out = in_sprite ? palette_out : 0;

    logic [10:0] hcount_pipe [3:0];
    always_ff @(posedge pixel_clk_in)begin
        hcount_pipe[0] <= hcount_in;
        for (int i=1; i<4; i = i+1)begin
        hcount_pipe[i] <= hcount_pipe[i-1];
        end
    end
    logic [9:0] vcount_pipe [3:0];
    always_ff @(posedge pixel_clk_in)begin
        vcount_pipe[0] <= vcount_in;
        for (int i=1; i<4; i = i+1)begin
        vcount_pipe[i] <= vcount_pipe[i-1];
        end
    end


endmodule

    

`default_nettype wire