`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.11.2018 17:51:49
// Design Name: 
// Module Name: sv_remapper_12k_top
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


module sv_remapper_12k_top #(

  parameter DATA_WIDTH       = 8,
  parameter IMAGE_KERNEL_12K = 64
  //parameter IMG_WIDTH        = 4096,
  //parameter IMG_HEIGHT       = 3072	
)(

  input  logic                  i_clk,
  input  logic                  i_aresetn,

  input  logic [12:0]           WIDTH,
  input  logic [12:0]           HEIGHT,
  input  logic                  i_odd_kernel,

  input  logic [DATA_WIDTH-1:0] s_axis_tdata,
  input  logic                  s_axis_tvalid,
  input  logic                  s_axis_tuser,
  input  logic                  s_axis_tlast,
  output logic                  s_axis_tready,


  output logic [DATA_WIDTH-1:0] m_axis_tdata,
  output logic                  m_axis_tvalid,
  output logic                  m_axis_tuser,
  output logic                  m_axis_tlast	
);
//
//
////////////////////////////////////////////////////////////////////////////////////


//show that we're ready to receive pixels
always_ff @( posedge i_clk, negedge i_aresetn )
  begin 
    if ( ~i_aresetn ) begin
      s_axis_tready <= 1'b0;
    end else begin
      s_axis_tready <= 1'b1;
    end
end
//
//

//////////////////////////////////////////////////////////////////////////////////
////INST////

//1. RECEIVER

//signals

logic [0:IMAGE_KERNEL_12K-1] [DATA_WIDTH-1:0] image_kernel_from_rec;
logic                                         kernel_is_ready_from_rec;
logic                                         kernel_is_odd_from_rec;


s_axis_remapper #(

  .DATA_WIDTH       ( DATA_WIDTH       ),
  .IMAGE_KERNEL_12K ( IMAGE_KERNEL_12K )

) remapper_receiver (

  .i_clk             ( i_clk                    ),
  .i_aresetn         ( i_aresetn                ),

  .i_odd_kernel      ( i_odd_kernel             ),

  .i_axis_tdata      ( s_axis_tdata             ),
  .i_axis_tvalid     ( s_axis_tvalid            ),
  .i_axis_tuser      ( s_axis_tuser             ),

  .o_image_kernel    ( image_kernel_from_rec    ),
  .o_kernel_is_ready ( kernel_is_ready_from_rec ),
  .o_kernel_is_odd   ( kernel_is_odd_from_rec   )
 
);
//
//

//////////////////////////////////////////////////////////////////////////////////
//2. REMAPPER

//signals

logic [0:IMAGE_KERNEL_12K-1] [DATA_WIDTH-1:0] image_kernel_remapped_from_rem;
logic                                         kernel_is_remapped_from_rem;

remapper_module #(

  .DATA_WIDTH       ( DATA_WIDTH       ),
  .IMAGE_KERNEL_12K ( IMAGE_KERNEL_12K )

) remapper_proc (

  .i_clk                   ( i_clk                          ),
  .i_aresetn               ( i_aresetn                      ),

  .i_image_kernel          ( image_kernel_from_rec          ),
  .i_kernel_is_ready       ( kernel_is_ready_from_rec       ),
  .i_kernel_is_odd         ( kernel_is_odd_from_rec         ),

  .o_image_kernel_remapped ( image_kernel_remapped_from_rem ),
  .o_kernel_is_remapped    ( kernel_is_remapped_from_rem    )	

);
//
//

//////////////////////////////////////////////////////////////////////////////////
//3. TRANSMITTER

m_axis_remapper #(

  .DATA_WIDTH       ( DATA_WIDTH       ),
  .IMAGE_KERNEL_12K ( IMAGE_KERNEL_12K )
  //.IMG_WIDTH        ( IMG_WIDTH        ),
  //.IMG_HEIGHT       ( IMG_HEIGHT       )

) remapper_transmitter (

  .i_clk                   ( i_clk                          ),
  .i_aresetn               ( i_aresetn                      ),

  .WIDTH                   ( WIDTH                          ),
  .HEIGHT                  ( HEIGHT                         ),


  .i_image_kernel_remapped ( image_kernel_remapped_from_rem ),
  .i_kernel_is_remapped    ( kernel_is_remapped_from_rem    ),

  .m_axis_tdata            ( m_axis_tdata                   ),
  .m_axis_tvalid           ( m_axis_tvalid                  ),
  .m_axis_tuser            ( m_axis_tuser                   ),
  .m_axis_tlast            ( m_axis_tlast                   )

);

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
