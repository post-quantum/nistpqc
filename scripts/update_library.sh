#!/bin/bash

if [[ $# -ne 2 ]]; then
	echo 
	echo "Usage: $0 [prefix] [object-file]"
	echo 
	exit -1
fi;

UNAME=`uname -s`
if [ "$UNAME" == "Linux" ]; then
	objcopy  `cat symbols.map | sed -e "s/^\(.*\) \(.*\)$/--redefine-sym \1=\2/g" | tr '\n' ' '` $2
    symbols=(`nm --defined-only -f p $2 | cut -f1 -d' ' | grep -v "^$1"`)
    for item in "${symbols[@]}"; do
        objcopy --redefine-sym $item="$1_$item" $2
    done
elif [ "$UNAME" == "Darwin" ]; then
    ld -r -arch `uname -m` -o $2 `cat symbols.map | sed -e 's/^\(.*\) \(.*\)$/-alias _\1 _\2 -exported_symbol _\2/g' | tr '\n' ' '` $2
else
    echo "Unsupported platform $UNAME"
    exit -1
fi