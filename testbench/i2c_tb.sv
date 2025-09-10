// Code your testbench here
// or browse Examples

`timescale 1ns/1ns
`include "i2c_slave.sv"
`include "i2c_master.sv" 
`include "i2c_addr_translator.sv"

module i2c_tb;
  reg clk;
  reg arst;
  reg [6:0] addr;
  reg [7:0] data_in;
  reg rw;
  reg en;
  wire scl;
  wire sda;
  wire busy;
  wire [7:0] data_out;
  wire conflict;
  
//   i2c_addr_trans dut(conflict_det);
  
  i2c_master M(.clk(clk),
               .arst(arst),
               .addr(addr),
               .data_in(data_in),
               .rw(rw),
               .en(en),
               .scl(scl),
               .sda(sda),
               .data_out(data_out),
               .busy(busy));
  
  i2c_slave #(.slave_address(7'b1001000)) S1(.scl(scl),
                                             .sda(sda));
  i2c_slave #(.slave_address(7'b1001111)) S2(.scl(scl),
                                             .sda(sda));    // Slave1 &   Slave2 data transfer
  
//   i2c_slave #(.slave_address(7'b1001111)) S1(.scl(scl),
//                                              .sda(sda));
//   i2c_slave #(.slave_address(7'b1001111)) S2(.scl(scl),
//                                              .sda(sda)); // conflict
  
  i2c_addr_translator  TRANSLATOR(.S1_en(S1.sda_en_s),
                                  .S2_en(S2.sda_en_s),
                                  .conflict(conflict));
  
  always #5  clk=~clk;
  
  initial begin       // data tranfer with Slave1
    S1.data_out=8'hfa;
    S2.data_out=8'h75;
    clk=0;
    arst=1;
    addr= 0;
    data_in= 0;
    rw= 0;
    en= 0;
    
    #250 arst=0;
    addr= 7'b1001000;
    data_in= 8'b10110011;
    rw=0;                 // write operation
    en=1;
    #2500 en=0;
    
    wait(!busy)
    #2500;
    addr= 7'b1001000;
    rw=1;                // read operation
    en=1;
    #2500 en=0;
  end
  
  
//   initial begin        // data transfer with Slave2
//     S1.data_out=8'hfa;
//     S2.data_out=8'h75;
//     clk=0;
//     arst=1;
//     addr= 0;
//     data_in= 0;
//     rw= 0;
//     en= 0;
    
//     #250 arst=0;
//     addr= 7'b1001111;
//     data_in= 8'b10110011;
//     rw=0;                 // write operation
//     en=1;
//     #2500 en=0;
    
//     wait(!busy)
//     #2500;
//     addr= 7'b1001111;
//     rw=1;                // read operation
//     en=1;
//     #2500 en=0;
//   end
  
  
//   initial begin        // data transfer with slave1 and Slave2 with same address which generates conflicts
//     S1.data_out=8'hfa;
//     S2.data_out=8'h75;
//     clk=0;
//     arst=1;
//     addr= 0;
//     data_in= 0;
//     rw= 0;
//     en= 0;
    
//     #250 arst=0;
//     addr= 7'b1001111;
//     data_in= 8'b10110011;
//     rw=0;                 // write operation
//     en=1;
//     #2500 en=0;
    
//     wait(!busy)
//     #2500;
//     addr= 7'b1001111;
//     rw=1;                // read operation
//     en=1;
//     #2500 en=0;
//   end
  
  initial begin
    $dumpfile("i2c.vcd");
    $dumpvars;
    #110000 $finish;
  end
endmodule