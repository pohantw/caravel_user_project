#!/bin/bash

# uncomment to install caravel (only need in first run)
# make install

export OPENLANE_ROOT=/tmp/pohan/openlane
export OPENLANE_TAG=v0.15
#export CARAVEL_ROOT=$(pwd)/caravel
export CARAVEL_ROOT=/tmp/pohan/final_upload_github_dir/ee272b_CGRA/caravel_user_project/caravel
export PRECHECK_ROOT=/tmp/pohan/precheck
export GCC_PATH=/tmp/pohan/riscv/bin

# new pdk
#export PDK_ROOT=/tmp/pohan/pdk-test
#export PDK_PATH=/tmp/pohan/pdk-test/sky130A
#export PDKPATH=/tmp/pohan/pdk-test/sky130A

# original pdk
export PDK_ROOT=/tmp/pohan/
export PDK_PATH=/tmp/pohan/sky130A
export PDKPATH=/tmp/pohan/sky130A

# gls pdk
#export PDK_ROOT=/tmp/pohan/pdk-gl
#export PDK_PATH=/tmp/pohan/pdk-gl/sky130A

# class pdk
#export PDK_ROOT=/afs/ir.stanford.edu/class/ee272/PDKS
#export PDK_PATH=$PDK_ROOT/sky130A

