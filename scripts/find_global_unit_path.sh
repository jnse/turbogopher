#!/bin/bash

if [ -z "${FPC_DIR}" ]; then
    for dir in {"/usr/lib/fpc","/usr/local/lib/fpc","/opt/fpc"}; do
        if [ -d $dir ]; then
            subdir=$(ls $dir | tail -n1)
            path="${dir}/${subdir}"
            if [ -d "${path}" ]; then
                echo "${path}"
                exit 0
            else
                echo "${dir}"
                exit 0
            fi
        fi
    done
fi

>&2 echo "Could not guess the path to your FPC directory."
>&2 echo "Please set \$FPC_DIR to your freepascal installation path."
exit 1
