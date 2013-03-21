#!/bin/bash

mkdir -p reports
rm -rf reports/*

for f in tests/*.lua; do
    NAME=$(basename ${f} .lua)
    lua5.1 ${f} > reports/${NAME}.tap
done
#EOF