`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.11.2018 16:47:02
// Design Name: 
// Module Name: remapper_module
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module remapper_module #(

  parameter DATA_WIDTH       = 8,
  parameter IMAGE_KERNEL_12K = 64

)(

  input  logic                                         i_clk,
  input  logic                                         i_aresetn,

  input  logic [0:IMAGE_KERNEL_12K-1] [DATA_WIDTH-1:0] i_image_kernel,
  input  logic                                         i_kernel_is_ready,
  input  logic                                         i_kernel_is_odd,

  output logic [0:IMAGE_KERNEL_12K-1] [DATA_WIDTH-1:0] o_image_kernel_remapped,
  output logic                                         o_kernel_is_remapped	

);
//
//
//////////////////////////////////////////////////////////////////////////////////

//REMAPPING
//signals
logic [0:IMAGE_KERNEL_12K-1] [DATA_WIDTH-1:0]  image_kernel_remapped;


//reg signals
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
    if ( ~i_aresetn ) begin
      o_image_kernel_remapped <= '{default: 'b0};
      o_kernel_is_remapped    <= 1'b0;
    end else begin
      o_image_kernel_remapped <= image_kernel_remapped;
      o_kernel_is_remapped    <= i_kernel_is_ready; 	
    end	
  end
//
//

//remapping logic
always_comb
  begin

    //image_kernel_remapped = '{default: 'b0};
    image_kernel_remapped = o_image_kernel_remapped;

    if ( i_kernel_is_ready ) begin
      //loops for remapping
      for ( int i = 0; i <= 3; i++ ) begin
        for ( int j = 0; j <= 7; j++ ) begin
          for ( int k = 0; k <= 1; k++ ) begin
          	if ( i_kernel_is_odd ) begin
              image_kernel_remapped[(3-i)*16 + (7-j)*2 + (1-k)] = i_image_kernel[k*32 + j*4 + i*1];
            end else begin
              image_kernel_remapped[i*16 + j*2 + k] = i_image_kernel[k*32 + j*4 + i*1];
            end  
          end	
        end	
      end
      //	
    end	

  end 

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
