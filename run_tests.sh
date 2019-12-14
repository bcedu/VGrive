#!/bin/bash
mv meson.build old_meson.build
mv test_meson.build meson.build
rm -r build
meson build --prefix=`pwd`/.testbuild
cd build
ninja
ninja install
cd ..
TESTDIR=`pwd`/tests .testbuild/bin/com.github.bcedu.vgrive
mv meson.build test_meson.build
mv old_meson.build meson.build
rm -r `pwd`/.testbuild
