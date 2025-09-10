module i2c_master(
  
  input clk,
  input arst,
  input [6:0] addr,   // 7-bit slave  addr
  input [7:0] data_in,   // data to be sent
  input en,
  input rw,
  
  output reg [7:0] data_out,   // data received
  output busy,
  output scl,
  inout sda
);
  
  parameter IDLE=3'd0, START=3'd1, ADDRESS=3'd2, ACK1=3'd3, DATA_TRANS=3'd4,             WRITE_ACK2=3'd5, READ_ACK2=3'd6, STOP=3'd7;
  
  reg [2:0] state=IDLE;
  reg [2:0] count=0;          
  reg [7:0] count_2=0;        // counter to generate i2c clk
  reg [7:0] count_3=0;        
  reg i2c_clk=0;              // 400 khz i2c clk
  reg scl_en_clk=0;           // 800 khz clk
  reg scl_en=0;               // enable for scl
  reg sda_en_m=0;               // enable for sda
  reg sda_out;                // output data for sda line
  reg [7:0] saved_addr;       // input address
  reg [7:0] saved_data;       // input data
  
  // generate i2c clk 400 khz
  
  always@(posedge clk)
    begin
      if(count_2==124)
        begin
          i2c_clk<=~i2c_clk;
          count_2<=0;
        end
      else
        count_2<=count_2+1;
    end
  
  always@(posedge clk)
    begin
      if(count_3==62)
        begin
          scl_en_clk<=~scl_en_clk;
          count_3<=0;
        end
      else
        count_3<=count_3+1;
    end
  
  // Logic for scl_en
  
  always@(negedge scl_en_clk,posedge arst)
    begin
      if(arst) scl_en<=0;
      else 
        begin
          if((state==IDLE)||(state==START)||(state==STOP)) scl_en<=0;
          else scl_en<=1;
        end
    end
  
  // FSM for MASTER
  
  always@(posedge i2c_clk,posedge arst)
    begin
      if(arst)
        state<=IDLE;
      else 
        begin
          case(state)
            
            IDLE:begin
              if(en)
                begin
                  state<=START;
                  saved_addr<={addr,rw};
                  saved_data<=data_in;
                end
              else
                state<= IDLE;
            end
            
            START: begin
              state<= ADDRESS;
              count<=7;
            end
            
            ADDRESS: begin
              if(count==0)
                begin
                  state<= ACK1;
                end
              else
                begin
                  count<=count-1;
                  state<= ADDRESS;
                end
            end
            
            ACK1: begin
              if(sda==0)           // 0 means ACK, 1 means NACK
                begin
                  state<= DATA_TRANS;
                  count<=7;
                end
              else
                begin
                  state<= STOP;   // IF NACK RECEIVED
                end
            end
            
            DATA_TRANS: begin
              if(saved_addr[0])
                begin
                  data_out[count]<=sda;   // read data from sda line
                  if(count==0)
                    begin
                      state<= WRITE_ACK2;
                    end
                  else
                    begin
                      count<=count-1;
                      state<= DATA_TRANS;
                    end
                end
                  else
                    begin
                      if(count==0)
                        begin
                          state<= READ_ACK2;
                        end
                      else
                        begin
                          count<=count-1;
                          state<= DATA_TRANS;
                        end
                    end
                end
            
            WRITE_ACK2: state<= STOP;
            
            READ_ACK2: begin
              if(sda==0 && en==1)
                begin
                  state<= IDLE;   // NACK
                end
              else
                begin
                  state<= STOP;   // ACK
                end
            end
            
            STOP: begin
              state<= IDLE;
            end
     
          endcase
        end
    end
  
  always@(negedge i2c_clk,posedge arst)
    begin
      if(arst)
        begin
          sda_en_m<=1;
          sda_out<=1;
        end
      else
        begin
          case(state)
            
            START: begin
              sda_out<= 0;   // start bit 0 indicate start of data trnasfer
              sda_en_m<=1;
            end
            
            ADDRESS:begin
              sda_out<= saved_addr[count];
              sda_en_m<=1;
            end
            
            ACK1: begin
              sda_en_m<=0;
            end
            
            DATA_TRANS: begin
              if(saved_addr[0])  // master perform read oper.
                begin
                  sda_en_m<=0;
                end
              else
                begin
                  sda_out<= saved_data[count];     // master perform write oper.
                  sda_en_m<=1;
                end
            end
            
            WRITE_ACK2: begin
              sda_en_m<=1;
              sda_out<=0;    // send ACK
            end
            
            READ_ACK2: begin
              sda_en_m<= 0;     // release sda for ACK from slave
            end
            
            STOP: begin
              sda_out<=1;
              sda_en_m<=1;
            end
            
          endcase
        end
    end
  
  assign scl = scl_en? i2c_clk: 1'b1;
  assign sda = sda_en_m? sda_out: 1'bz;
  assign busy = (state==IDLE)? 1'b0:1'b1;
  
endmodule