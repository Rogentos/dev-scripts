#!/bin/bash

set -x

world_file='/var/lib/portage/world'
deselect='/tmp/deselect'

while read package ; do
    printf "${package}: "
    check=$(qdepends -Q ${package} 2>&1)
    if [[ -n ${check} ]]; then
        if [[ ${check} == *'no matches found'* ]]; then
            printf "No matches found for your query\n"
        else
            emerge_check=$(emerge -p --quiet --depclean ${package} 2>&1)
            if [[ -n ${emerge_check} ]]; then
                printf "Needs to stay in @world\n"
            else
                printf "Can be deselected\n"
                printf "${package}\n" >> ${deselect}
            fi
        fi
    fi
done < ${world_file}
