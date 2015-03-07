#!/bin/bash

if [ -z "${FORMAT}" ] ; then
	FORMAT=TAP
fi

case ${FORMAT} in
	"TAP") EXT=tap; OUT_FORCE=true ;;
	"JUNIT") EXT=xml; OUT_FORCE=false ;;
	"TEXT") EXT=txt; OUT_FORCE=true ;;
	*) echo "ERROR: Unknown format ${FORMAT}"; exit 1 ;;
esac

mkdir -p reports
rm -rf reports/*

function  do_test() {
	echo "testing $1 -> reports/${1}.${EXT}"
	if ${OUT_FORCE} ; then
		cat<<EOF|lua5.1 - > reports/${1}.${EXT}
require "tests/${1}"
---- Control test output:
local lu = LuaUnit
lu:setOutputType('${FORMAT}')
lu:setVerbosity(1)
lu:run()
EOF
	else
	cat<<EOF|lua5.1 -
require "tests/${1}"
---- Control test output:
local lu = LuaUnit
lu:setOutputType('${FORMAT}')
lu:setFname('reports/${1}.${EXT}')
lu:setVerbosity(1)
lu:run()
EOF
	fi
}

if [[ -n "$@" ]]; then
	for i in $@; do
		if [ ! -f "$i" ]; then
			echo "No $f found"
		else
			do_test $(basename "$i" .lua)
		fi
	done
	exit 0
fi

for i in $(find tests -name '*.lua' ! -name test_\*) ; do
	do_test $(basename "$i" .lua)
done
