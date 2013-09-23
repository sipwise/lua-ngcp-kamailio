#!/bin/bash

mkdir -p reports
rm -rf reports/*

if [[ ! -z "$@" ]]; then
	for i in $@; do
		f="tests/$i.lua"
		if [ ! -f $f ]; then
			echo "No $f found"
		else
			echo "testing $f -> reports/${i}.tap"
			cat<<EOF|lua5.1 - > reports/${i}.tap
require "tests/$i"
---- Control test output:
lu = LuaUnit
lu:setOutputType('TAP')
lu:setVerbosity(1)
lu:run()
EOF
		fi
	done
	exit 0
fi

lua5.1 tests/test_all.lua > reports/test_all.tap
#EOF