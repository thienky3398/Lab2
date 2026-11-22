#!/bin/bash
set -e
mkdir -p bai-tap doc logs rtl sw tb sim

cat > .gitignore << 'EOF'
build/
obj_dir/
*.vcd
*.fst
*.o
*.vvp
__pycache__/
build_synth.ys
EOF

cat > rtl/mul16.sv << 'EOF'
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
EOF

cat > tb/tb_mul16.sv << 'EOF'
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
    for (int i = 0; i < 2000; i++) check($urandom, $urandom);

    if (errors == 0) $display("PASS");
    else             $display("TONG SO LOI: %0d", errors);
    $finish;
  end
endmodule
EOF

cat > sw/demo.cpp << 'EOF'
#include "Vmul16.h"
#include "verilated.h"
#include <cstdio>

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  Vmul16* dut = new Vmul16;
  unsigned tests[][2] = {{3, 5}, {100, 200}, {65535, 65535}, {1234, 4321}};
  for (auto& t : tests) {
    dut->a = t[0]; dut->b = t[1]; dut->eval();
    printf("%5u x %5u = %10u\n", t[0], t[1], (unsigned)dut->p);
  }
  delete dut;
  return 0;
}
EOF

cat > Makefile << 'EOF'
TOP ?= mul16
RTL := $(wildcard rtl/*.sv)
TB  := $(wildcard tb/*.sv)
LIB ?= sky130.lib

.PHONY: sim synth demo clean

sim:
    verilator --binary --timing --assert -Wno-fatal --top-module tb_$(TOP) $(RTL) $(TB) -Mdir build/sim
    ./build/sim/Vtb_$(TOP)

synth:
    @mkdir -p logs
    @echo "read_verilog -sv rtl/*.sv"  >  build_synth.ys
    @echo "synth -flatten -top $(TOP)" >> build_synth.ys
    @echo "ltp -noff"                  >> build_synth.ys
    @if [ -f $(LIB) ]; then \
      echo "dfflibmap -liberty $(LIB)" >> build_synth.ys; \
      echo "abc -liberty $(LIB)"       >> build_synth.ys; \
      echo "stat -liberty $(LIB)"      >> build_synth.ys; \
    else \
      echo "Chua co $(LIB): chay stat chung (khong co dien tich um2)"; \
      echo "stat" >> build_synth.ys; \
    fi
    yosys -q -l logs/synth.log build_synth.ys
    @tail -n 30 logs/synth.log

demo:
    verilator --cc --exe --build -Wno-fatal --top-module $(TOP) $(RTL) sw/demo.cpp -Mdir build/demo
    ./build/demo/V$(TOP)

clean:
    rm -rf build build_synth.ys
EOF
sed -i 's/^    /\t/' Makefile

cat > tim_fail.sh << 'EOF'
#!/bin/bash
mkdir -p logs
make sim > logs/sim.log 2>&1
if grep -i "FAIL\|TONG SO LOI" logs/sim.log; then
  echo ">> Co loi, xem logs/sim.log"
  exit 1
else
  echo ">> Khong co FAIL"
fi
EOF
chmod +x tim_fail.sh

cat > README.md << 'EOF'
# Lab 2

## Cach chay
    make sim          # testbench tu kiem tra
    ./tim_fail.sh     # chay sim va loc FAIL
    make synth        # tong hop Yosys (can sky130.lib)
    make demo         # phan cung ao

## Cau truc
- bai-tap/  cau tra loi Phan 1-2
- rtl/      ma RTL (mul16.sv)
- tb/       testbench
- sw/       C++ / Python
- doc/      bao cao, dac ta
- logs/     log chay, nhat ky loi
EOF

touch bai-tap/.gitkeep doc/.gitkeep logs/.gitkeep sim/.gitkeep
echo "Xong. Chay tiep: make sim"
