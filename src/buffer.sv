`timescale 1ns / 1ps
`default_nettype none

// so I'm 75% sure my convolution is working properly. buffer is producing outputs, but I believe the data that goes
// into the convolution's cache is all messed up due to sequential vs combinational logic timing and pipelining


module buffer (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [10:0] hcount_in, //current hcount being read
    input wire [9:0] vcount_in, //current vcount being read
    input wire [15:0] pixel_data_in, //incoming pixel
    input wire data_valid_in, //incoming  valid data signal

    output logic [15:0] line_buffer_out [2:0], //output pixels of data
    output logic [10:0] hcount_out, //current hcount being read
    output logic [9:0] vcount_out, //current vcount being read
    output logic data_valid_out //valid data out signal
  );
    
    // Your code here!
    assign data_valid_out = data_valid_in_pipe[2];
    assign hcount_out = hcount_pipe[2];

    //assign hcount_out = hcount_in;
    //assign vcount_out = vcount_pipe[1]; // FIX VCOUNT
    logic [9:0] vcount_temp;
    always_comb begin
        if (vcount_in < 3) vcount_out = vcount_in + 238;
        else if (vcount_in > 1) vcount_out = vcount_in - 2;
        else if (vcount_in > 241) vcount_out = vcount_in - 242;
        else if (vcount_in > 481) vcount_out = vcount_in - 482;
        else if (vcount_in > 721) vcount_out = vcount_in - 722;
        else vcount_out = vcount_in - 2;
    end

    logic [9:0] old_vcount_in;
    always_ff @(posedge clk_in)begin
        old_vcount_in <= vcount_in;
        if (rst_in)begin
            mux <= 0;
        end else begin
            if (!(old_vcount_in == vcount_in)) begin // new line!
                //ena <= 0;
                mux <= mux==2'b11 ? 0 : mux + 1; // buffer only displays if mux is sequential
            end else if (data_valid_in) begin
                //ena <= 1; // read!
            end else if (!data_valid_in)begin
                //ena <= 0;
            end
        end
    end

    logic [15:0] bram_in [3:0]; // BRAM ins/write-enables/outs
    logic [3:0] wea;
    logic [15:0] bram_out [3:0];
    logic [1:0] mux;
    logic ena;

    always_comb begin
        //if (!(old_vcount_in == vcount_in)) begin
        //    mux = mux==2'b11 ? 0 : mux + 1;
        //end
        if (data_valid_in) ena = 1;
        else ena = 0;
    end

    logic [15:0] yuh0;
    logic [15:0] yuh1;
    logic [15:0] yuh2;

    assign yuh0 = line_buffer_out[0];
    assign yuh1 = line_buffer_out[1];
    assign yuh2 = line_buffer_out[2];
    
    always_comb begin // mux changing BRAM roles 1,2,3,4 -> 2,3,4,1 -> 3,4,1,2 -> 4,1,2,3 etc.
        //if (!data_valid_in) begin
            //wea = 4'b0000;
        //end else begin
            case (mux)
                2'b00: begin
                    //if (data_valid_in) begin
                        wea = 4'b1000;
                        line_buffer_out[2] = bram_out[0];
                        line_buffer_out[1] = bram_out[1];
                        line_buffer_out[0] = bram_out[2];
                        bram_in[3] = pixel_data_in;
                        bram_in[2] = pixel_data_in;
                        bram_in[1] = pixel_data_in;
                        bram_in[0] = pixel_data_in;
                    //end
                end
                2'b01: begin
                    //if (data_valid_in) begin
                        wea = 4'b0001;
                        line_buffer_out[2] = bram_out[1];
                        line_buffer_out[1] = bram_out[2];
                        line_buffer_out[0] = bram_out[3];
                        bram_in[0] = pixel_data_in;
                        bram_in[3] = pixel_data_in;
                        bram_in[2] = pixel_data_in;
                        bram_in[1] = pixel_data_in;
                    //end
                end
                2'b10: begin
                    //if (data_valid_in) begin
                        wea = 4'b0010;
                        line_buffer_out[2] = bram_out[2];
                        line_buffer_out[1] = bram_out[3];
                        line_buffer_out[0] = bram_out[0];
                        bram_in[1] = pixel_data_in;
                        bram_in[0] = pixel_data_in;
                        bram_in[3] = pixel_data_in;
                        bram_in[2] = pixel_data_in;
                    //end
                end
                2'b11: begin
                    //if (data_valid_in) begin
                        wea = 4'b0100;
                        line_buffer_out[2] = bram_out[3];
                        line_buffer_out[1] = bram_out[0];
                        line_buffer_out[0] = bram_out[1];
                        bram_in[2] = pixel_data_in;
                        bram_in[1] = pixel_data_in;
                        bram_in[0] = pixel_data_in;
                        bram_in[3] = pixel_data_in;
                    //end
                end
            endcase
        //end
    end
    /*
    always_ff @(posedge clk_in)begin
     // mux changing BRAM roles 1,2,3,4 -> 2,3,4,1 -> 3,4,1,2 -> 4,1,2,3 etc.
        if (data_valid_in) begin
            case (mux)
                2'b00: begin
                    //if (data_valid_in) begin
                        wea <= 4'b1000;
                        line_buffer_out[2] <= bram_out[0];
                        line_buffer_out[1] <= bram_out[1];
                        line_buffer_out[0] <= bram_out[2];
                        bram_in[3] <= pixel_data_in;
                        bram_in[2] <= pixel_data_in;
                        bram_in[1] <= pixel_data_in;
                        bram_in[0] <= pixel_data_in;
                    //end
                end
                2'b01: begin
                    //if (data_valid_in) begin
                        wea <= 4'b0001;
                        line_buffer_out[2] <= bram_out[1];
                        line_buffer_out[1] <= bram_out[2];
                        line_buffer_out[0] <= bram_out[3];
                        bram_in[0] <= pixel_data_in;
                        bram_in[3] <= pixel_data_in;
                        bram_in[2] <= pixel_data_in;
                        bram_in[1] <= pixel_data_in;
                    //end
                end
                2'b10: begin
                    //if (data_valid_in) begin
                        wea <= 4'b0010;
                        line_buffer_out[2] <= bram_out[2];
                        line_buffer_out[1] <= bram_out[3];
                        line_buffer_out[0] <= bram_out[0];
                        bram_in[1] <= pixel_data_in;
                        bram_in[0] <= pixel_data_in;
                        bram_in[3] <= pixel_data_in;
                        bram_in[2] <= pixel_data_in;
                    //end
                end
                2'b11: begin
                    //if (data_valid_in) begin
                        wea <= 4'b0100;
                        line_buffer_out[2] <= bram_out[3];
                        line_buffer_out[1] <= bram_out[0];
                        line_buffer_out[0] <= bram_out[1];
                        bram_in[2] <= pixel_data_in;
                        bram_in[1] <= pixel_data_in;
                        bram_in[0] <= pixel_data_in;
                        bram_in[3] <= pixel_data_in;
                    //end
                end
            endcase
        end else begin
            wea <= 4'b0000;
        end
    end */

    generate // 4 BRAMS
        genvar i;
        for (i=0; i<4; i=i+1)begin : my_brams
            xilinx_true_dual_port_read_first_1_clock_ram #(
                .RAM_WIDTH(16),                       // Specify RAM data width
                .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
                .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
                .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
            ) bramn (
                .addra(hcount_in[8:0]),     // Address bus, width determined from RAM_DEPTH
                .addrb(hcount_in[8:0]),
                .dina(bram_in[i]),       // RAM input data, width determined from RAM_WIDTH
                .dinb(),
                .clka(clk_in),       // Clock
                .wea(wea[i]),         // Write enable
                .web(),
                .ena(ena),
                .enb(ena),         // RAM Enable, for additional power savings, disable port when not in use
                .rsta(rst_in),       // Output reset (does not affect memory contents)
                .rstb(rst_in),
                .regcea(1'b1),   // Output register enable
                .regceb(1'b1),
                .douta(),      // RAM output data, width determined from RAM_WIDTH
                .doutb(bram_out[i])
            );
        end
    endgenerate

    logic data_valid_in_pipe [2:0]; // pipelining 2 cycles between valid in and out
    always_ff @(posedge clk_in)begin
        data_valid_in_pipe[0] <= data_valid_in;
        for (int i=1; i<3; i = i+1)begin
            data_valid_in_pipe[i] <= data_valid_in_pipe[i-1];
        end
    end

    logic [10:0] hcount_pipe [2:0]; // pipelining 2 cycles between hcount in and out
    always_ff @(posedge clk_in)begin
        hcount_pipe[0] <= hcount_in;
        for (int i=1; i<3; i = i+1)begin
            hcount_pipe[i] <= hcount_pipe[i-1];
        end
    end

    logic [9:0] vcount_pipe [1:0]; // pipelining 2 cycles between hcount in and out
    always_ff @(posedge clk_in)begin
        vcount_pipe[0] <= vcount_temp;
        for (int i=1; i<2; i = i+1)begin
            vcount_pipe[i] <= vcount_pipe[i-1];
        end
    end
endmodule


`default_nettype wire