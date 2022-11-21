`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

  //your design here!
  logic state;
  localparam ADDING = 0;
  localparam DIVIDING = 1;

  logic [31:0] x_sum; // division and sum variables
  logic [31:0] y_sum;
  logic [31:0] x_count;
  logic [31:0] y_count;

  logic [31:0] x_final; // division results
  logic [31:0] y_final;

  logic div_x_out; // x division valid
  logic div_y_out; // y division valid

  logic div_x_done; // signal when x division is done (since valid_out's are only up for 1 cycle)
  logic div_y_done; // signal when y division is done

  assign x_out = x_final[10:0];
  assign y_out = y_final[9:0];

  divider div_x(.clk_in(clk_in), // X DIVIDER
              .rst_in(rst_in),
              .dividend_in(x_sum),
              .divisor_in(x_count),
              .data_valid_in(tabulate_in),
              .quotient_out(x_final),
              .remainder_out(),
              .data_valid_out(div_x_out),
              .error_out(),
              .busy_out());

  divider div_y(.clk_in(clk_in), // Y DIVIDER
              .rst_in(rst_in),
              .dividend_in(y_sum),
              .divisor_in(y_count),
              .data_valid_in(tabulate_in),
              .quotient_out(y_final),
              .remainder_out(),
              .data_valid_out(div_y_out),
              .error_out(),
              .busy_out());

  always_ff @(posedge clk_in)begin
    if (rst_in) begin
      state <= ADDING;
      div_x_done <= 0;
      div_y_done <= 0;
      x_sum <= 0;
      y_sum <= 0;
      x_count <= 0;
      y_count <= 0;
      valid_out <= 0;
    end else begin
        case (state)
          ADDING: begin
            valid_out <= 0;
            if (valid_in)begin // POINT TO BE ADDED
              x_sum <= x_sum + x_in;
              y_sum <= y_sum + y_in;
              x_count <= x_count + 1;
              y_count <= y_count + 1;
            end else if (tabulate_in && x_count > 0 && y_count > 0)begin // TRIGGER CoM CALCULATION, ensuring valid recordings
              state <= DIVIDING; // MINOR FSM STARTS
              div_x_done <= 0;
              div_y_done <= 0;
            end
          end
          DIVIDING: begin
            if(div_x_out)begin // if valid pulse from x divider
              div_x_done <= 1; // GOT X RESULT
            end
            if(div_y_out)begin // if valid pulse from y divider
              div_y_done <= 1; // GOT Y RESULT
            end
            if(div_x_done && div_y_done)begin // GOT BOTH RESULTS - DONE!
              state <= ADDING;
              valid_out <= 1; // results are valid!
              x_sum <= 0; // restart counts and sums     
              y_sum <= 0;
              x_count <= 0;
              y_count <= 0;
            
            end
          end
        endcase
    end
  end

endmodule
`default_nettype wire
