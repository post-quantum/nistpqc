#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo 
	echo "Usage: $0 [prefix] [object-file]"
	echo 
	exit -1
fi;

symbols=(`$NM --defined-only -f p $2 | cut -f1 -d' '`)
for item in "${symbols[@]}"; do
	$OBJCOPY --redefine-sym $item="$1$item" $2
done
