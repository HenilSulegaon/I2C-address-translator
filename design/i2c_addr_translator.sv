
module i2c_addr_translator(
  input S1_en,S2_en,
  output reg conflict
);
  
  always @(*)
    begin
      if(S1_en && S2_en)
        conflict = 1;
      else
        conflict = 0;
    end
endmodule