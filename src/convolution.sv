`timescale 1ns / 1ps
`default_nettype none

module convolution #(
    parameter K_SELECT=0)(
    input wire clk_in,
    input wire rst_in,
    input wire [15:0] data_in [2:0],
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [15:0] line_out
    );

    // Your code here!
    logic signed [2:0][2:0][7:0] coeffs;
    logic signed [7:0] shift;

    kernels #(
        .K_SELECT(K_SELECT)
        ) what (
        .rst_in(rst_in),
        .coeffs(coeffs),
        .shift(shift)
    );

    assign hcount_out = hcount_pipe[1]; // should be 2?
    assign vcount_out = vcount_pipe[1]; //
    assign data_valid_out = data_valid_pipe[2]; // should be 1?

    logic [15:0] cache [2:0][2:0];
    logic signed [16:0] r [2:0][2:0];
    logic signed [16:0] g [2:0][2:0];
    logic signed [16:0] b [2:0][2:0];
    logic signed [16:0] toshift_r;
    logic signed [16:0] toshift_g;
    logic signed [16:0] toshift_b;
    logic signed [16:0] temp_r;
    logic signed [16:0] temp_g;
    logic signed [16:0] temp_b;

    always @(*) begin
        r[0][0] = $signed({1'b0,cache[0][0][15:11]}) * $signed(coeffs[0][0]);
        r[0][1] = $signed({1'b0,cache[0][1][15:11]}) * $signed(coeffs[0][1]);
        r[0][2] = $signed({1'b0,cache[0][2][15:11]}) * $signed(coeffs[0][2]);
        r[1][0] = $signed({1'b0,cache[1][0][15:11]}) * $signed(coeffs[1][0]);
        r[1][1] = $signed({1'b0,cache[1][1][15:11]}) * $signed(coeffs[1][1]);
        r[1][2] = $signed({1'b0,cache[1][2][15:11]}) * $signed(coeffs[1][2]);
        r[2][0] = $signed({1'b0,cache[2][0][15:11]}) * $signed(coeffs[2][0]);
        r[2][1] = $signed({1'b0,cache[2][1][15:11]}) * $signed(coeffs[2][1]);
        r[2][2] = $signed({1'b0,cache[2][2][15:11]}) * $signed(coeffs[2][2]);
        g[0][0] = $signed({1'b0,cache[0][0][10:5]}) * $signed(coeffs[0][0]);
        g[0][1] = $signed({1'b0,cache[0][1][10:5]}) * $signed(coeffs[0][1]);
        g[0][2] = $signed({1'b0,cache[0][2][10:5]}) * $signed(coeffs[0][2]);
        g[1][0] = $signed({1'b0,cache[1][0][10:5]}) * $signed(coeffs[1][0]);
        g[1][1] = $signed({1'b0,cache[1][1][10:5]}) * $signed(coeffs[1][1]);
        g[1][2] = $signed({1'b0,cache[1][2][10:5]}) * $signed(coeffs[1][2]);
        g[2][0] = $signed({1'b0,cache[2][0][10:5]}) * $signed(coeffs[2][0]);
        g[2][1] = $signed({1'b0,cache[2][1][10:5]}) * $signed(coeffs[2][1]);
        g[2][2] = $signed({1'b0,cache[2][2][10:5]}) * $signed(coeffs[2][2]);
        b[0][0] = $signed({1'b0,cache[0][0][4:0]}) * $signed(coeffs[0][0]);
        b[0][1] = $signed({1'b0,cache[0][1][4:0]}) * $signed(coeffs[0][1]);
        b[0][2] = $signed({1'b0,cache[0][2][4:0]}) * $signed(coeffs[0][2]);
        b[1][0] = $signed({1'b0,cache[1][0][4:0]}) * $signed(coeffs[1][0]);
        b[1][1] = $signed({1'b0,cache[1][1][4:0]}) * $signed(coeffs[1][1]);
        b[1][2] = $signed({1'b0,cache[1][2][4:0]}) * $signed(coeffs[1][2]);
        b[2][0] = $signed({1'b0,cache[2][0][4:0]}) * $signed(coeffs[2][0]);
        b[2][1] = $signed({1'b0,cache[2][1][4:0]}) * $signed(coeffs[2][1]);
        b[2][2] = $signed({1'b0,cache[2][2][4:0]}) * $signed(coeffs[2][2]);
        toshift_r = $signed($signed(r[0][0]) + $signed(r[0][1]) + $signed(r[0][2]) + $signed(r[1][0]) + $signed(r[1][1]) + $signed(r[1][2]) + $signed(r[2][0]) + $signed(r[2][1]) + $signed(r[2][2])); 
        toshift_g = $signed($signed(g[0][0]) + $signed(g[0][1]) + $signed(g[0][2]) + $signed(g[1][0]) + $signed(g[1][1]) + $signed(g[1][2]) + $signed(g[2][0]) + $signed(g[2][1]) + $signed(g[2][2]));
        toshift_b = $signed($signed(b[0][0]) + $signed(b[0][1]) + $signed(b[0][2]) + $signed(b[1][0]) + $signed(b[1][1]) + $signed(b[1][2]) + $signed(b[2][0]) + $signed(b[2][1]) + $signed(b[2][2])); 
    end

    logic first;   
    logic second;
    logic signed [30:0] temp_line;
    
    always_ff @(posedge clk_in) begin
        if(rst_in) begin
            line_out <= 0;
        end else begin
            /*
            temp_line <= {toshift_r, toshift_g, toshift_b} >>> shift;
            line_out <= $signed(temp_line) < $signed(0) ? 16'b0 : temp_line; */
            
            temp_r <= $signed($signed(toshift_r) >>> $signed(shift));
            temp_g <= $signed($signed(toshift_g) >>> $signed(shift));
            temp_b <= $signed($signed(toshift_b) >>> $signed(shift));
            line_out <= {($signed(temp_r) < $signed(0) ? 5'b0 : temp_r[4:0]),
                        ($signed(temp_g) < $signed(0) ? 6'b0 : temp_g[5:0]),
                        ($signed(temp_b) < $signed(0) ? 5'b0 : temp_b[4:0])};
        end
    end

    always_ff @(posedge clk_in) begin // UPDATING CACHE
        if (rst_in)begin
            cache[0][0] <= 0;
            cache[1][0] <= 0;
            cache[2][0] <= 0;
            cache[0][1] <= 0;
            cache[1][1] <= 0;
            cache[2][1] <= 0;
            cache[0][2] <= 0;
            cache[1][2] <= 0;
            cache[2][2] <= 0;
        end else if (data_valid_in)begin
            cache[0][0] <= data_in[2];
            cache[1][0] <= data_in[1];
            cache[2][0] <= data_in[0];

            cache[0][1] <= cache[0][0];
            cache[1][1] <= cache[1][0];
            cache[2][1] <= cache[2][0];

            cache[0][2] <= cache[0][1];
            cache[1][2] <= cache[1][1];
            cache[2][2] <= cache[2][1];
        end
    end

    // PIPELINING
    logic data_valid_pipe [3:0]; // pipelining 3 cycles between valid in and out
    always_ff @(posedge clk_in)begin
        data_valid_pipe[0] <= data_valid_in;
        for (int i=1; i<4; i = i+1)begin
            data_valid_pipe[i] <= data_valid_pipe[i-1];
        end
    end

    logic [10:0] hcount_pipe [3:0]; // pipelining 3 cycles between hcount in and out
    always_ff @(posedge clk_in)begin
        hcount_pipe[0] <= hcount_in;
        for (int i=1; i<4; i = i+1)begin
            hcount_pipe[i] <= hcount_pipe[i-1];
        end
    end

    logic [9:0] vcount_pipe [3:0]; // pipelining 3 cycles between vcount in and out
    always_ff @(posedge clk_in)begin
        vcount_pipe[0] <= vcount_in;
        for (int i=1; i<4; i = i+1)begin
            vcount_pipe[i] <= vcount_pipe[i-1];
        end
    end
    // always_ff @(posedge clk_in) begin
    //   // Make sure to have your output be set with registered logic!
    //   // Otherwise you'll have timing violations.
    //   line_out <= {r, g, 1'b0, b};
    // end
endmodule

`default_nettype wire
