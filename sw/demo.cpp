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
