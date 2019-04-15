`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.11.2018 12:25:41
// Design Name: 
// Module Name: tb_remapper_12k_top
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


module tb_remapper_12k_top();

localparam DATA_WIDTH       = 8;
localparam IMAGE_KERNEL_12K = 64;
localparam WIDTH            = 256;
localparam HEIGHT           = 128;



//signals
logic clk;
logic aresetn;

logic [DATA_WIDTH-1:0]   tdata;
logic                    tvalid;
logic                    tuser;
logic                    tlast;           
//
//
tb_video_stream #(
  .N                ( DATA_WIDTH ),
  .width            ( WIDTH      ),
  .height           ( HEIGHT     ) 

) data_generator (
  .sys_clk          ( clk     ),
  .sys_aresetn      ( aresetn ),

  .reg_video_tdata  ( tdata   ),
  .reg_video_tvalid ( tvalid  ),
  .reg_video_tlast  ( tlast   ),
  .reg_video_tuser  ( tuser   )
);
//
//


//signals
logic [DATA_WIDTH-1:0] tdata_rem;
logic                  tvalid_rem;
logic                  tuser_rem;
logic                  tlast_rem; 
// 
sv_remapper_12k_top #(

  .DATA_WIDTH       ( DATA_WIDTH       ),
  .IMAGE_KERNEL_12K ( IMAGE_KERNEL_12K ),
  .IMG_WIDTH        ( WIDTH            ),
  .IMG_HEIGHT       ( HEIGHT           )

) UUT (

  .i_clk         ( clk        ),
  .i_aresetn     ( aresetn    ),

  .s_axis_tdata  ( tdata      ),
  .s_axis_tvalid ( tvalid     ),
  .s_axis_tuser  ( tuser      ),
  .s_axis_tlast  ( tlast      ),
  .s_axis_tready (            ),


  .m_axis_tdata  ( tdata_rem  ),
  .m_axis_tvalid ( tvalid_rem ),
  .m_axis_tuser  ( tuser_rem  ),
  .m_axis_tlast  ( tlast_rem  )

);
//
//

tb_savefile_axis_data #(

  .N      ( DATA_WIDTH ),
  .height ( HEIGHT     ),
  .width  ( WIDTH      )

) save_image_to_file (
  .i_sys_clk          ( clk           ),
  .i_sys_aresetn      ( aresetn       ),

  .i_reg_video_tdata  ( tdata_rem     ),
  .i_reg_video_tvalid ( tvalid_rem    ),
  .i_reg_video_tlast  ( tuser_rem     ),
  .i_reg_video_tuser  ( tlast_rem     )
  
  );

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
