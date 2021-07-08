#!/bin/bash

# setting
top="user_proj_example"
base_dir="../mflowgen/tile_array"
build_target="build_top_w695"

# create path
gds_path="$base_dir/$build_target/*-signoff/outputs/design-merged.gds"
lef_path="$base_dir/$build_target/*-signoff/outputs/design.lef"
def_path="$base_dir/$build_target/*-signoff/outputs/design.def.gz"
gl_path="$base_dir/$build_target/*-signoff/outputs/design.vcs.v"
#spi_path="$base_dir/$build_target/*-gds2spice/outputs/design_extracted.spice"

# create file name

gds_file="./gds/$top.gds"
lef_file="./lef/$top.lef"
def_file="./def/$top.def.gz"
gl_file="./verilog/gl/$top.v"
#spi_file="./spi/lvs/$top.spice"

# remove old files
if [ -f $gds_file ]; then
    rm -rf $gds_file
    echo "remove existed $gds_file"
fi
if [ -f $lef_file ]; then
    rm -rf $lef_file
    echo "remove existed $lef_file"
fi
if [ -f $def_file ]; then
    rm -rf $def_file
    echo "remove existed $def_file"
fi
if [ -f $gl_file ]; then
    rm -rf $gl_file
    echo "remove existed $gl_file"
fi
#if [ -f $spi_file ]; then
#    rm -rf $spi_file
#    echo "remove existed $spi_file"
#fi

# move file
echo "moving $gds_path to $gds_file"
cp $gds_path $gds_file
echo "moving $lef_path to $lef_file"
cp $lef_path $lef_file
echo "moving $def_path to $def_file"
cp $def_path $def_file
echo "moving $gl_path to $gl_file"
cp $gl_path $gl_file
#echo "moving $spi_path to $spi_file"
#cp $spi_path $spi_file

#unzip .gz files
echo "gunzip $def_file"
gunzip $def_file
