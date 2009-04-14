#! /bin/bash

if [ "$1" = "--help" ]; then
   echo This script implemtents the function update
   echo for the Inverse Boltzmann Method
   echo Usage: ${0##*/} step_nr
   echo Needs:  run_or_exit, \$source_wrapper, update_POT.pl
   exit 0
fi

[[ -n "$1" ]] || die "${0##*/}: Missing argument"

update_single="$($SOURCE_WRAPPER --direct update_ibm_single.sh)" || die "${0##*/}: $SOURCE_WRAPPER --direct update_ibm_single.sh failed"
for_all non-bonded "${update_single} ${1}"
