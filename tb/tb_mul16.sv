module tb_mul16;
  logic [15:0] a, b;
  logic [31:0] p;
  int errors = 0;

  mul16 dut (.*);

  task automatic check(input logic [15:0] x, input logic [15:0] y);
    a = x; b = y; #1;
    if (p !== 32'(x) * 32'(y)) begin
      $display("FAIL: %0d * %0d = %0d (mong doi %0d)", x, y, p, 32'(x)*32'(y));
      errors++;
    end
  endtask

  initial begin
    check(0, 0);
    check(16'hFFFF, 16'hFFFF);
    check(1, 16'hFFFF);
    check(16'h8000, 2);
    for (int i = 0; i < 2000; i++) check(16'($urandom), 16'($urandom));

    if (errors == 0) $display("PASS");
    else             $display("TONG SO LOI: %0d", errors);
    $finish;
  end
endmodule
