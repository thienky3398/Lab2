module mul16 (
  input  logic [15:0] a,
  input  logic [15:0] b,
  output logic [31:0] p
);
  always_comb begin
    p = '0;
    for (int i = 0; i < 16; i++)
      if (b[i]) p = p + (32'(a) << i);
  end
endmodule
