
module i2c_slave(
  input scl,
  inout sda
);
  
  parameter READ_ADDR=2'd0, SEND_ACK1=2'd1, DATA_TRANS=2'd2, SEND_ACK2=2'd3;
  parameter slave_address= 7'b0000000;
  
  reg [1:0] state=READ_ADDR;
  reg [6:0] addr;
  reg rw;
  reg [7:0] data_in;
  reg [7:0] data_out= 8'b11011101;  // stored data
  reg sda_out=0;
  reg sda_en_s=0;
  reg sda_en_2=1;
  reg [2:0] count=7;
  reg start=0;
  reg stop=1;
  
  always@(posedge sda or negedge sda)
    begin
      if(sda==0 && scl==1)
        begin
          start<= 1;
          stop<= 0;
        end
      if(sda==1 && scl==1)
        begin
          start<= 0;
          stop<= 1;
        end
    end
  
  always@(posedge scl)
    begin
      if(stop) begin
        state <= READ_ADDR;
        count <= 7;
        sda_en_s <= 0;
        sda_en_2 <= 1;
      end
      
      if(start)
        begin
          case(state)
            
            READ_ADDR: begin
              if(count==0)
                begin
                  state<= SEND_ACK1;
                  sda_en_2<= 1;
                  rw <= sda;
                end
              else
                begin
                  addr[count-1]<= sda;
                  count<= count-1;
                  state<= READ_ADDR;
                end
            end
            
            SEND_ACK1: begin
              if(addr==slave_address)
                begin
                  state<= DATA_TRANS;
                  count<= 7;
                end
              else
                begin
                  sda_en_s <= 0; 
                  sda_en_2 <= 1;
                  state <= READ_ADDR;
                end
            end
            
            DATA_TRANS: begin
              if(!rw)
                begin
                  data_in[count]<=sda;
                  if(count==0)  state<= SEND_ACK2;
                  else 
                    begin
                      count<= count-1;
                      state<= DATA_TRANS;
                    end
                end
              else
                    begin
                      if(count==0)
                        begin
                          state<= READ_ADDR;
                        end
                      else
                        begin
                          count <= count-1;
                          state<= DATA_TRANS;
                        end
                    end
                end
            
            
            SEND_ACK2: begin
              state<= READ_ADDR;
              sda_en_2 <=0;
              count<= 7;
            end
          endcase
          
        end
    end
  
  always@(negedge scl)
    begin
      case(state)
        
        READ_ADDR: begin
          sda_en_s<=0;           // don't drive sda during addr. read
        end
        
        SEND_ACK1: begin
          if(slave_address==addr)
            begin
              sda_out<= 0;    // send ACK
              sda_en_s<=1;
            end
          else   sda_en_s<=0;    // NACK
        end
        
        DATA_TRANS: begin
          if(!rw)
            begin
              sda_en_s<=0;       // don't drive sda , slave read-master write
            end
          else
            begin
              sda_out<= data_out[count];
              sda_en_s<=1;       // send data on sda slave write
              if(count == 0) begin
              // Wait for master ACK/NACK
              state <= SEND_ACK2;
                end
            end
        end
        
        SEND_ACK2: begin
          sda_out<= 0;
          sda_en_s<= 1;         // send ACK
        end
      endcase
    end
  
  assign sda =(sda_en_s && sda_en_2)? sda_out:1'bz;   // Tri-state SDA line
endmodule