#! /bin/bash 

#note the space at the beginning and the end !!!
not_to_check=" ${0##*/} errorbars.sh "

if [ -z "$1" ]; then
  echo MIssing argument >&2 
  echo help with ${0##*/} --help >&2
  exit 1
fi

if [ "$1" = "--help" ]; then
  echo Usage: ${0##*/} WORD FILE1 FILE2 ...
  echo Checks if a program is in NEEDS block of a file
  echo "Example ${0##*/} cg.inverse.program *.sh"
  echo WORD = -- does some magic
  echo "WORD is set to \$(for i in *.sh *.pl; do ./\$i --help 2>&1 | sed -n 's/NEEDS: \+\(.*\) *$/\1/p' | sed 's/ /\n/g'; done | sort | uniq)"
  echo "missing FILE means '*.sh *.pl'"
  echo "So if you are LAZY just run '${0##*/} --'"
  echo It will always ignore: $not_to_check
  echo USES: sed sort uniq csg_get_property csg_get_interaction_property
  exit 0
fi

if [ "$1" = "--" ]; then
  whates="$(for i in *.sh *.pl; do [[ -z "${not_to_check##* $i *}" ]] && continue; ./$i --help 2>&1 | sed -n 's/NEEDS: \+\(.*\) *$/\1/p' | sed 's/ /\n/g'; done | sort | uniq )"
else
  whates="$1"
fi
shift

if [ -z "$1" ]; then
  set -- *.pl *.sh
fi

echo files to check: $@
echo
echo what to check: $whates
echo
for i in $@; do
  [[ -z "${not_to_check##* $i *}" ]] && continue
  echo Checking $i
  [[ ! -x "$i" ]] && echo "$i is not executable" && continue
  ./$i --help &> /dev/null || { echo "$i has no help"; continue; }
  [[ -z "(./$i --help | grep "NEEDS:")" ]] && echo "$i has no NEEDS in help" && continue
  for what in $whates; do
    what=${what//./\.}
    what=${what//\*/\*}
    if [ -z "${what##cg*}" ]; then
      if [ -z "${i%%*.pl}" ]; then
        what2="csg_get_property\(\\\"$what\\\"\)"
      else
        what2="csg_get_property '?$what[^a-zA-Z_.]'?"
      fi
    else
      if [ -z "${i%%*.pl}" ]; then
        what2="csg_get_interaction_property\(\\\"$what\\\"\)"
      else
        what2="csg_get_interaction_property (--allow-empty )?$what[^a-zA-Z_.]"
      fi
    fi
    #pattern in the content of the file
    pattern1="$what2"
    #pattern in the help
    pattern2="NEEDS:.*[[:space:]]$what([[:space:]]|$)"
    in_help="no"
    in_content="no"
    [[ -n "$(grep -Ev "NEEDS:" "$i" | grep -Ee "$pattern1")" ]] && in_content="yes"
    [[ -n "$(./$i --help | grep -Ee "$pattern2")" ]] && in_help="yes"
    #what found in file and uses -> ok
    [[ "$in_help" = "yes" ]] && [[ "$in_content" = "yes" ]] && continue
    #what found in file, but not in uses
    [[ "$in_help" = "no" ]] && [[ "$in_content" = "yes" ]] && \
      echo "$i: $what found, but NOT in NEEDS -> add it"
    #what not found in file, but in uses
    [[ "$in_help" = "yes" ]] && [[ "$in_content" = "no" ]] && \
      echo "$i: $what found in NEEDS, but NOT in content -> remove it"
    #what not found in file and uses -> ok
    [[ "$in_help" = "no" ]] && [[ "$in_content" = "no" ]] && continue
  done
done