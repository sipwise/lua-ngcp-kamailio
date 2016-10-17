#!/bin/bash

RESULTS=${RESULTS:-.}
ID=0

if [ -z "${FORMAT}" ] ; then
	FORMAT=TAP
fi

case ${FORMAT} in
	"TAP") EXT=tap; OUT_FORCE=true ;;
	"JUNIT") EXT=xml; OUT_FORCE=false ;;
	"TEXT") EXT=txt; OUT_FORCE=true ;;
	*) echo "ERROR: Unknown format ${FORMAT}"; exit 1 ;;
esac

mkdir -p "${RESULTS}"/reports
rm -rf "${RESULTS}"/reports/*

# unique id across files
# See TT#4590
function fix_id() {
	(( ID += 1))
	local tmp_id
	tmp_id=$(printf "%05d\n" "$ID")
	sed -i "s/id=\"00001\"/id=\"$tmp_id\"/" "$1"
}

function  do_test() {
	local RES="${RESULTS}/reports/${1}.${EXT}"
	echo "testing $1 -> ${RES}"
	if ${OUT_FORCE} ; then
		cat<<EOF |lua5.1 - > "${RES}"
EXPORT_ASSERT_TO_GLOBALS = true
require "tests/${1}"
---- Control test output:
local lu = LuaUnit
lu:setOutputType('${FORMAT}')
lu:setVerbosity(1)
lu:run()
EOF
	else
		cat<<EOF |lua5.1 -
EXPORT_ASSERT_TO_GLOBALS = true
require "tests/${1}"
---- Control test output:
local lu = LuaUnit
lu:setOutputType('${FORMAT}')
lu:setFname('${RES}')
lu:setVerbosity(1)
lu:run()
EOF
		if [[ "${FORMAT}" = "JUNIT" ]] ; then
			fix_id "${RES}"
		fi
	fi
}


if [[ -n "$@" ]]; then
	for i in "$@"; do
		if [ ! -f "$i" ]; then
			echo "No $i found"
		else
			do_test "$(basename "$i" .lua)"
		fi
	done
	exit 0
fi

find tests -name '*.lua' ! -name test_\*| while read -r i ; do
	do_test "$(basename "$i" .lua)"
done
