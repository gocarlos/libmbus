#!/bin/bash

# normal compilation
# export CC=gcc-8
# export CXX=g++-8
rm -rf _build
mkdir _build
cd _build
cmake ..
cmake --build . -j
