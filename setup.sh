#!/bin/bash

# uncomment to install caravel (only need in first run)
# make install

export OPENLANE_ROOT=/tmp/pohan/openlane
export OPENLANE_TAG=v0.15
export CARAVEL_ROOT=$(pwd)/caravel
export PRECHECK_ROOT=/tmp/pohan/precheck
export GCC_PATH=/tmp/pohan/riscv/bin

# new pdk
export PDK_ROOT=/tmp/pohan/pdk-test
export PDK_PATH=/tmp/pohan/pdk-test/sky130A

# original pdk
#export PDK_ROOT=/tmp/pohan/
#export PDK_PATH=/tmp/pohan/sky130A

# class pdk
#export PDK_ROOT=/afs/ir.stanford.edu/class/ee272/PDKS
#export PDK_PATH=$PDK_ROOT/sky130A

