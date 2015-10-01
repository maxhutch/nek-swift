#!/bin/bash


# Usage:
# $1 : tdir
# $2 : name
# $3 : njob
# $4 : ninc
# $5 : nwrite

echo $# $0 $1 $2 >> /projects/HighAspectRTI/experiments/debug-maxhutch/my_map.log

$1=$2
$2=$4
$3=$6
$4=$8
$5=${10}


count=0
for i in $(seq -f "%05g" $(($4 + 1)) $4 $(($4 * $3 + 1))); do
  count1=0
  for j in $(seq -f "%03g" 0 $(($5 - 1)) ); do
    echo "["${count}"]["${count1}"] "${1}"/A"${j}"/"${2}${j}".f"${i}
    echo "["${count}"]["${count1}"] "${1}"/A"${j}"/"${2}${j}".f"${i} >> /projects/HighAspectRTI/map_log.out
    count1=$((count1 + 1))
  done
  count=$((count + 1))
done
