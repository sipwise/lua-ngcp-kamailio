#!/bin/bash
mkdir -p reports
for f in tests/*.lua; do
    NAME=$(basename ${f} .lua)
    lua5.1 ${f} > reports/${NAME}.tap
done
#EOF