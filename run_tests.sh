#!/bin/bash

mkdir -p reports
rm -rf reports/*

#for f in tests/test_*.lua; do
#    NAME=$(basename ${f} .lua)
#    lua5.1 ${f} > reports/${NAME}.tap
#done

lua5.1 tests/test_all.lua > reports/test_all.tap
#EOF