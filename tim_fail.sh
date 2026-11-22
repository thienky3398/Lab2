#!/bin/bash
mkdir -p logs
make sim > logs/sim.log 2>&1
if grep -i "FAIL\|TONG SO LOI" logs/sim.log; then
  echo ">> Co loi, xem logs/sim.log"
  exit 1
else
  echo ">> Khong co FAIL"
fi
