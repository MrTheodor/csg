#! /bin/bash
# 
# Copyright 2009 The VOTCA Development Team (http://www.votca.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [ "$1" = "--help" ]; then
cat <<EOF
${0##*/}, version %version%
This script implemtents the function update
for the Inverse Boltzmann Method

Usage: ${0##*/} step_nr

USES:  die msg csg_get_property for_all do_external

NEEDS: cg.inverse.program 
EOF
   exit 0
fi

check_deps "$0"

[[ -n "$1" ]] || die "${0##*/}: Missing argument"

msg "Calc rdf"
sim_prog="$(csg_get_property cg.inverse.program)" 
for_all non-bonded do_external rdf $sim_prog
for_all non-bonded do_external update ibm_single "${1}"
