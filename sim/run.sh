#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$repo/run-output-bash}"
if [[ -e "$out" ]]; then
  echo "Output directory already exists: $out" >&2
  exit 1
fi
for tool in vlib vlog vsim; do
  command -v "$tool" >/dev/null || { echo "Missing simulator tool: $tool" >&2; exit 1; }
done
mkdir -p "$out"
vsim -version >"$out/simulator-version.txt" 2>&1

sources=()
for list in "$repo/sim/rtl.f" "$repo/sim/testbenches.f"; do
  while IFS= read -r rel || [[ -n "$rel" ]]; do
    [[ -z "$rel" || "$rel" == \#* ]] && continue
    sources+=("$repo/$rel")
  done < "$list"
done
tops=(sram_test axi_slave_test axi_master_test axi_reset_test master_responder_test slave_model_test standalone_top_test)
markers=('PASS SRAM checks=20' 'PASS AXI slave checks=58' 'PASS AXI master/slave SRAM 26 transactions' 'PASS AXI partial AW/W reset' 'MASTER_RESPONDER_PASS checks=' 'SLAVE_MODEL_PASS checks=' 'STANDALONE_TOP_PASS checks=')
for i in "${!tops[@]}"; do
  top="${tops[i]}"
  test_out="$out/$top"
  mkdir "$test_out"
  pushd "$test_out" >/dev/null
  vlib work >library.log 2>&1 || { echo "vlib failed: $top" >&2; exit 1; }
  vlog -sv "${sources[@]}" >compile.log 2>&1 || { echo "vlog failed: $top" >&2; exit 1; }
  vsim -c -onfinish exit "$top" -do 'onerror {quit -code 1}; run -all; quit -code 0' >simulation.log 2>&1 || { echo "vsim failed: $top" >&2; exit 1; }
  if ! grep -Fq "${markers[i]}" simulation.log ||
     ! grep -Fq '$finish' simulation.log ||
     ! grep -Fq '# Errors: 0, Warnings: 0' simulation.log ||
     grep -Eq '^[[:space:]]*#?[[:space:]]*\*\*[[:space:]]+(Error|Fatal):' simulation.log; then
    echo "Incomplete or failing simulation: $top" >&2
    exit 1
  fi
  popd >/dev/null
  echo "PASS $top"
done
echo "REGRESSION_PASS tests=${#tops[@]} output=$out"
