#!/bin/bash

# setup the pdk path
export PDK_ROOT=/tmp/pohan
export PDK_PATH=/tmp/pohan/sky130A
export PDKPATH=/tmp/pohan/sky130A

# copy the gds that is hardened by openlane
cp ../openlane/user_project_wrapper/runs/user_project_wrapper/results/magic/user_project_wrapper.gds .

# delete previous version (if exist)
if [ -f "hand-routed.gds" ]; then
    rm hand-routed.gds
fi

# run the fix script from Tim
magic -noconsole -dnull timfix.tcl | tee timfix.log

# put back the hand-routed.gds to submit folder
if [ -f "../gds/user_project_wrapper.gds" ]; then
    rm ../gds/user_project_wrapper.gds
fi
cp hand-routed.gds ../gds/user_project_wrapper.gds
