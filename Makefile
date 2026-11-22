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
