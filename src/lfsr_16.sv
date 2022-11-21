`default_nettype none
module lfsr_16 ( input wire clk_in, input wire rst_in,
                    input wire [15:0] seed_in,
                    output logic [15:0] q_out);

logic [15:0] q = 16'hABCD;
assign q_out = q;
always_ff @(posedge clk_in)begin
    if(rst_in)begin
      q <= seed_in;
    end else begin
      q[15] <= q[15]^q[14];
      q[0]  <= q[15];
      q[1]  <= q[0];
      q[2]  <= q[1]^q[15];
      for(int i = 3; i<=14; i= i+1)begin
        q[i] <= q[i-1];
      end
    end
  end
endmodule
`default_nettype none