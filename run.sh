#!/bin/bash
echo "========================"
echo "== Running VGrive     =="
echo "== Compiling tests... =="
echo "========================"
rm -r build
meson build --prefix=`pwd`/.testbuild
cd build
ninja
ninja install
cd ..
echo "======================"
echo "== Compiled!  =="
echo "== Running tests... =="
echo "======================"
TESTDIR=`pwd`/tests .testbuild/bin/com.github.bcedu.vgrive
