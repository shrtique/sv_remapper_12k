`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////






module s_axis_remapper #(

  parameter DATA_WIDTH       = 8,
  parameter IMAGE_KERNEL_12K = 64

)(

  input  logic                                         i_clk,
  input  logic                                         i_aresetn,

  input  logic [DATA_WIDTH-1:0]                        i_axis_tdata,
  input  logic                                         i_axis_tvalid,
  input  logic                                         i_axis_tuser,

  output logic [0:IMAGE_KERNEL_12K-1] [DATA_WIDTH-1:0] o_image_kernel,
  output logic                                         o_kernel_is_ready,
  output logic                                         o_kernel_is_odd


);


//REG input data in image kernel buffer
//signals
//logic [0:63] [DATA_WIDTH-1:0] input_kernel_buffer;

//
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
    if ( ~i_aresetn ) begin 
      o_image_kernel <= '{default: 'b0};
    end else begin
      if ( i_axis_tvalid ) begin
        o_image_kernel <= {o_image_kernel[1:IMAGE_KERNEL_12K-1], i_axis_tdata};
      end	
    end	
  end
//
//


//Counter of input pixels to show that image kernel is ready
//signals
logic [5:0] pixels_in_kernel;
//
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
    if ( ~i_aresetn ) begin
      pixels_in_kernel  <= 0;
      o_kernel_is_ready <= 1'b0;

    end else begin

      o_kernel_is_ready <= 1'b0;	

      if ( i_axis_tvalid ) begin
        pixels_in_kernel <= pixels_in_kernel + 1;

        if ( pixels_in_kernel == (IMAGE_KERNEL_12K-1) ) begin
          pixels_in_kernel  <= 0;
          o_kernel_is_ready <= 1'b1;
        end 
      end	
    end	
  end 

always_ff @( posedge i_clk, negedge i_aresetn ) 
  begin
    if ( ~i_aresetn ) begin
      o_kernel_is_odd <= 1'b0;
    end else begin
      if ( i_axis_tuser ) begin
        o_kernel_is_odd <= 1'b0;
      end else if ( o_kernel_is_ready ) begin
        o_kernel_is_odd <= ~o_kernel_is_odd;  
      end
    end	
  end 	


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule