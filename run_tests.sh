#!/bin/bash

if [ -z "${FORMAT}" ] ; then
	FORMAT=TAP
fi

case ${FORMAT} in
	"TAP") EXT=tap ;;
	"JUNIT") EXT=xml ;;
	"TEXT") EXT=txt ;;
	*) echo "ERROR: Unknown format ${FORMAT}"; exit 1 ;;
esac

mkdir -p reports
rm -rf reports/*

function  do_test() {
	echo "testing $1 -> reports/${1}.${EXT}"
	cat<<EOF|lua5.1 -
require "tests/${1}"
---- Control test output:
local lu = LuaUnit
lu:setOutputType('${FORMAT}')
lu:setFname('reports/${1}.${EXT}')
lu:setVerbosity(1)
lu:run()
EOF
}

if [[ ! -z "$@" ]]; then
	for i in $@; do
		if [ ! -f $i ]; then
			echo "No $f found"
		else
			do_test $(basename $i .lua)
		fi
	done
	exit 0
fi

for i in $(find tests -name '*.lua' | grep -v test_) ; do
	do_test $(basename $i .lua)
done
