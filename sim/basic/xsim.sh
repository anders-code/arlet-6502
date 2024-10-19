#!/bin/sh -x

TOP="tb_basic"

rm -fr xsim.dir/

/opt/Xilinx/Vivado/2023.1/bin/xvlog -sv -relax -nolog -i ../.. -d CONFIG_TT=1 -d SIM=1 ../../rtl/[ca]*.sv ../utils/tb*.sv "${TOP}.sv"
rm -f *.pb *.jou

/opt/Xilinx/Vivado/2023.1/bin/xelab -debug off -relax -nolog -snapshot "${TOP}" -top "${TOP}"
rm -f *.pb *.jou

if [ -z "$1" ]; then
    set -- -R;
fi

/opt/Xilinx/Vivado/2023.1/bin/xsim -nolog "${TOP}" "$@"
rm -f *.pb *.jou
