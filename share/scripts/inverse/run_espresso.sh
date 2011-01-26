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
This script runs espresso
for the Inverse Boltzmann Method

Usage: ${0##*/}

USES: critical get_number_tasks csg_get_property check_deps


EOF
    exit 0
fi

check_deps "$0"

esp="$(csg_get_property cg.inverse.espresso.blockfile "conf.esp.gz")"
[ -f "$esp" ] || die "${0##*/}: espresso blockfile '$esp' not found"

espout="$(csg_get_property cg.inverse.espresso.blockfile_out "confout.esp.gz")"

n_steps="$(csg_get_property cg.inverse.espresso.n_steps)"
[ -z "$n_steps" ] && die "${0##*/}: Could not read espresso property n_steps"

method="$(csg_get_property cg.inverse.method)"

esp_bin="$(csg_get_property cg.inverse.espresso.bin "Espresso_bin")"
[ -n "$(type -p $esp_bin)" ] || die "${0##*/}: esp_bin binary '$esp_bin' not found"

esp_dir="$(csg_get_property --allow-empty cg.inverse.espresso.scriptdir)"
if [ -z "${esp_dir}" ]; then
  [ -z "$ESPRESSO_SCRIPTS" ] && die "${0##*/}: cg.inverse.espresso.scriptdir of the xml setting file was empty and ESPRESSO_SCRIPTS not set in the environment.\nEspresso needs this variable to find its scripts."
  [ -d "${ESPRESSO_SCRIPTS}" ] || die "${0##*/}: ESPRESSO_SCRIPTS ($ESPRESSO_SCRIPTS) is not a directory"
else
  export ESPRESSO_SCRIPTS="${esp_dir}"
  [ -d "${ESPRESSO_SCRIPTS}" ] || die "${0##*/}: cg.inverse.espresso.scriptdir ($ESPRESSO_SCRIPTS) is not a directory"
fi

exclusions="$(csg_get_property cg.inverse.espresso.exclusions 0)"
[ -z "$exclusions" ] && die "${0##*/}: Could not read espresso property exclusions"

debug="$(csg_get_property cg.inverse.espresso.debug "no")"

# Topology+trajectory file
traj_esp="$(csg_get_property cg.inverse.espresso.traj "top_traj.esp")"


# Different Espresso scripts depending on the method used
################ IBI ###################
if [ "$method" = "ibi" ]; then
    
    n_snapshots="$(csg_get_property cg.inverse.espresso.n_snapshots)"
    [ -z "$n_snapshots" ] && die "${0##*/}: Could not read espresso property n_snapshots"

    # Make sure all particle indexes have been loaded into the blockfile
    index_vars=$(for_all non-bonded \
	csg_get_interaction_property inverse.espresso.index1)
    index_vars="$index_vars $(for_all non-bonded \
    csg_get_interaction_property inverse.espresso.index2)"
    index_vars=$(for i in $index_vars; do echo $i; done | sort -u)
    for i in $index_vars; do
	[ -n "$(gzip -cd $esp | grep $i)" ] || die "${0##*/}: can't find index list: $i"
    done
    
    # load blockfile into Espresso, then integrate for $n_steps steps, then save blockfile
    esp_script="$(mktemp esp.run.tcl.XXXXX)"
    esp_success="$(mktemp esp.run.done.XXXXX)"
    cat > $esp_script <<EOF
set in [open "|gzip -cd $esp" r]
while { [blockfile \$in read auto] != "eof" } {}
close \$in

# Are num_molecules and num_atoms both already defined?
if { ![info exists num_molecules] || ![info exists num_atoms] } {
  # Loop over all particles to calculate num_molecules and num_atoms
  set moltypes ""
  set num_molecules 0
  set num_atoms ""
  set num_atoms_mol 0
  for { set j 0 } { \$j < [setmd n_part] } { incr j } {
    # look for molecules
    if {[lsearch \$moltypes [part \$j print molecule]] == -1} {
      lappend moltypes [part \$j print molecule]
      incr num_molecules
      if {\$j != 0 } { lappend num_atoms \$num_atoms_mol }
      set num_atoms_mol 1
    } else {
      incr num_atoms_mol
    }
  }
  lappend num_atoms \$num_atoms_mol
}

# Set particle exclusions
if { $exclusions != 0 } {
  part auto_exclusions $exclusions
}

# Main integration loop
puts "Main integration starts"
set pos_out [open $traj_esp w]
blockfile \$pos_out write variable box_l
blockfile \$pos_out write tclvariable num_molecules
blockfile \$pos_out write tclvariable num_atoms
close \$pos_out
for { set j 0 } { \$j < $n_snapshots } { incr j } {
  integrate $n_steps
  puts "step \$j of $n_snapshots"
  if { $debug == "yes" } {
    puts "  [analyze energy]"
  }
  set pos_out [open $traj_esp a]
  if { [has_feature "MASS"] } {
    blockfile \$pos_out write particles {id type molecule mass pos v}
  } else {
    blockfile \$pos_out write particles {id type molecule pos v}
  }
  close \$pos_out
}

set out [open "|gzip -c - > $espout" w]
blockfile \$out write variable all
blockfile \$out write interactions
blockfile \$out write thermostat
blockfile \$out write tclvariable num_molecules
blockfile \$out write tclvariable num_atoms
blockfile \$out write tclvariable {$index_vars}
if { [has_feature "MASS"] } {
  blockfile \$out write particles {id type molecule mass pos v}
} else {
  blockfile \$out write particles {id type molecule pos v}
}
blockfile \$out write bonds
close \$out

set out [open $esp_success w]
close \$out
EOF
    
    tasks=$(get_number_tasks)
    if [ $tasks -gt 1 ]; then
	mpicmd=$(csg_get_property --allow-empty cg.inverse.parallel.cmd)
        mpi_check=$(csg_get_property cg.inverse.espresso.mpi_check "yes")
	if [ "${mpi_check}" = "yes" ]; then
	  #in most cases mpirun want -x option to export environment to compute nodes
	  [ -n "${mpicmd//*-x ESPRESSO_SCRIPTS*}" ] && die "${0##*/}: You have forgotten to add '-x  ESPRESSO_SCRIPTS' to the cg.inverse.parallel.cmd!\n
For most mpi implementation this is needed to export the environment variable ESPRESSO_SCRIPTS on compute nodes.\n
To disable this check set cg.inverse.espresso.mpi_check to 'no'"
	critical $mpicmd $esp_bin $esp_script
    else
	critical $esp_bin $esp_script
    fi
    [ -f "$esp_success" ] || die "${0##*/}: Espresso run did not end successfully. Check log."    
    [ -f "$traj_esp" ] || die "${0##*/}: Espresso traj file '$traj_esp' not found after running Espresso"
    [ -f "$espout" ] || die "${0##*/}: Espresso end coordinate '$espout' not found after running Espresso"
    
else
    die "${0##*/}: ESPResSo only supports method: ibi"
fi
