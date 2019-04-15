`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////






module m_axis_remapper #(

  parameter DATA_WIDTH       = 8,
  parameter IMAGE_KERNEL_12K = 64,
  parameter IMG_WIDTH        = 4096,
  parameter IMG_HEIGHT       = 3072

)(

  input  logic                                         i_clk,
  input  logic                                         i_aresetn,

  input  logic [0:IMAGE_KERNEL_12K-1] [DATA_WIDTH-1:0] i_image_kernel_remapped,
  input  logic                                         i_kernel_is_remapped,

  output logic [DATA_WIDTH-1:0]                        m_axis_tdata,
  output logic                                         m_axis_tvalid,
  output logic                                         m_axis_tuser,
  output logic                                         m_axis_tlast

);


//SIGNALS
typedef enum logic [2:0] {IDLE, TUSER, KERNEL_TRANSMITTING, WAIT_FOR_NEW_KERNEL, TLAST} statetype;
statetype state, nextstate;

logic [DATA_WIDTH-1:0] axis_tdata;
logic                  axis_tvalid;
logic                  axis_tuser;
logic                  axis_tlast;

logic                  en_counter, en_counter_reg;

logic [5:0]            kernel_addr_next_to_rd;
logic [11:0]           img_pixel_counter;
logic [11:0]           img_line_counter;
logic                  end_of_frame;
logic                  next_is_tlast;
//

//state_reg
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
    if   ( ~i_aresetn ) state <= IDLE;
    else                state <= nextstate;	
  end
//
//

//data_reg
always_ff @( posedge i_clk, negedge i_aresetn )
  begin
    if ( ~i_aresetn ) begin
      m_axis_tdata   <= '{ default: 'b0};
      m_axis_tvalid  <= 1'b0;
      m_axis_tuser   <= 1'b0;
      m_axis_tlast   <= 1'b0;

      en_counter_reg <= 1'b0;

    end else begin
      m_axis_tdata   <= axis_tdata;
      m_axis_tvalid  <= axis_tvalid;	
      m_axis_tuser   <= axis_tuser;
      m_axis_tlast   <= axis_tlast;

      en_counter_reg <= en_counter;

    end   
  end
//
//


always_comb
  begin

    nextstate   = state;
    
    axis_tdata  = m_axis_tdata;
    axis_tvalid = 1'b0;
    axis_tuser  = 1'b0;
    axis_tlast  = 1'b0;

    en_counter  = en_counter_reg;

    case ( state )

     
      IDLE : begin

        en_counter = 1'b0;

        if ( i_kernel_is_remapped ) begin

          axis_tdata  = i_image_kernel_remapped [kernel_addr_next_to_rd];
          axis_tvalid = 1'b1;
          axis_tuser  = 1'b1;

          en_counter  = 1'b1;

          nextstate   = TUSER;

        end	

      end //IDLE
      

      TUSER : begin
      	axis_tdata  = i_image_kernel_remapped [kernel_addr_next_to_rd];
        axis_tvalid = 1'b1;

        nextstate   = KERNEL_TRANSMITTING;

      end //TUSER


      KERNEL_TRANSMITTING : begin
        
        //if we've finished kernel transmitting and next is not ready -> go waiting
      	if ( ( ~i_kernel_is_remapped ) && ( kernel_addr_next_to_rd == 0 ) ) begin
          axis_tdata = 0;
          axis_tvalid = 1'b0;
          	
          en_counter = 1'b0;	
          nextstate = WAIT_FOR_NEW_KERNEL;
        end	else begin

          axis_tdata  = i_image_kernel_remapped [kernel_addr_next_to_rd];
          axis_tvalid = 1'b1;
          
          nextstate = KERNEL_TRANSMITTING;
          
          //tlast should appear with the last pixel
          if ( img_pixel_counter == (IMG_WIDTH-2) ) begin	
            axis_tlast = 1'b1;
            nextstate  = TLAST;
          end 
        end	
      	

      end //KERNEL_TRANSMITTING


      WAIT_FOR_NEW_KERNEL : begin
        
        if ( i_kernel_is_remapped ) begin

          axis_tdata  = i_image_kernel_remapped [kernel_addr_next_to_rd];
          axis_tvalid = 1'b1;
          
          en_counter  = 1'b1;

          nextstate   = KERNEL_TRANSMITTING;

        end 

      end //WAIT_FOR_NEW_KERNEL	
      


      TLAST : begin
      	
        if ( i_kernel_is_remapped ) begin

          axis_tdata  = i_image_kernel_remapped [kernel_addr_next_to_rd];
          axis_tvalid = 1'b1;
          
          en_counter  = 1'b1;

          nextstate   = KERNEL_TRANSMITTING;

        end else begin

      	  en_counter = 1'b0;

          nextstate  = WAIT_FOR_NEW_KERNEL;
        end  
        
        //end of frame
        if ( ( img_line_counter == (IMG_HEIGHT-1) ) && ( img_pixel_counter == (IMG_WIDTH-1) ) ) begin

          nextstate = IDLE;
        end	

      end //TLAST

      
      default : nextstate = IDLE;	

    endcase	
  
  end	
//
//


//COUNTER of transmitted pixels
always @( posedge i_clk, negedge i_aresetn )
  begin
    if ( ~i_aresetn ) begin
      img_pixel_counter <= 0;
      img_line_counter  <= 0;
    end else begin
      
      //use reg-ed signal to do counting of output pixels from 0 up to IMG_WIDTH-1
      if ( en_counter_reg ) begin
        img_pixel_counter <= img_pixel_counter + 1;
      end

      //the stuff below is better to do without minding of s_axis_tvalid
      if ( img_pixel_counter == IMG_WIDTH - 1 ) begin
      	img_pixel_counter  <= 0;
        img_line_counter   <= img_line_counter + 1;

        if ( img_line_counter == IMG_HEIGHT - 1 ) begin
          img_line_counter <= 0;	
        end 	
      end    
    end
  end 


always @( posedge i_clk, negedge i_aresetn )
  begin
    if ( ~i_aresetn ) begin
      kernel_addr_next_to_rd <= 0;
    end else begin
      
      //use signal directly form logic (e.g to know nextaddress during TUSER state)
      //state:                  <IDLE><TUSER><KERNEL_TRANSMITTING>
      //kernel_addr_next_to_rd: <0000><00001><2><3><4><5>........
      //img_pixel_counter:      <0000><00000><1><2><3><4>........ 

      if ( en_counter ) begin
        kernel_addr_next_to_rd <= kernel_addr_next_to_rd + 1;
      end
      
      //the stuff below is better to do without minding of s_axis_tvalid
      if ( kernel_addr_next_to_rd == IMAGE_KERNEL_12K - 1 ) begin
      	kernel_addr_next_to_rd  <= 0;
      end    
    end
  end 

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule