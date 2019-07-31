#!/bin/bash
# Author & Copyright holder: Rogentos Team, 2018-2019
# LICENSE: GPL v2
# This script recompiles all packages in PKGDIR
# It will always compile latest version
# Packages that are going to be compiled, are not installed

set -x

if [[ -e "/etc/portage/make.conf" ]] ; then
        . /etc/portage/make.conf
        if [[ -z ${PKGDIR} ]] ; then
                export PKGDIR="${PKGDIR:-/usr/portage/packages}"
        else
                export PKGDIR="${PKGDIR:-}"
        fi
else
        export PKGDIR="${PKGDIR:-/usr/portage/packages}"
fi


cd ${PKGDIR}


# Section that gives the user the power to input PKG_INPUT_ARGUMENT
# the argument is passed to the finder, within the $PKGDIR folder
# any folder that gets found with that pattern, the script will compile everything
# within it
export PKG_INPUT_ARGUMENT="${PKG_INPUT_ARGUMENT:-}"

if [[ -z "${PKG_INPUT_ARGUMENT}" ]] ; then
        echo -e ""
        echo -e "Compiling folders:"
        export local PKG_FIND_LS_CMD="${PKG_FIND_LS_CMD:-$(ls | sed -e '/Packages/d')}"
        echo -e ""
else
        echo -e "You are recompiling everything with pattern: $PKG_INPUT_ARGUMENT"
        export local PKG_FIND_LS_CMD="$(ls | sed -e '/Packages/d' | grep "${PKG_INPUT_ARGUMENT}" )"
fi

# updating portage structures before any action taken
epkg update

# nothing else than category packages should be here
# if there is something else, please make sure you exclude it


if [[ -e "/tmp/PKG_LIST_UNIQUE_REVS" ]] ; then
	rm /tmp/PKG_LIST_UNIQUE_REVS
fi

if [[ -e "/tmp/PKG_LIST_UNIQUE_NOREVS" ]] ; then
	rm /tmp/PKG_LIST_UNIQUE_NOREVS
fi

if [[ -z "${PKG_INPUT_ARGUMENT}" ]] ; then
	for i in $( find . -iname "*.tbz2" | grep -- "-r[0-9999]" | cut -c 3- ) ; do

          for f in $( echo "${i%-r*}" ) ; do

	  	echo "${f%-*}" >> /tmp/PKG_LIST_UNIQUE_REVS

	  done

	done
fi


if [[ -z "${PKG_INPUT_ARGUMENT}" ]] ; then
	for i in $( find . -iname "*.tbz2" | grep -v -- "-r[0-9999]" | cut -c 3- ) ; do

            for f in $( echo "${i}" ) ; do

                echo "${f%-*}" >> /tmp/PKG_LIST_UNIQUE_NOREVS

            done

	done

fi

if [[ -e "/tmp/PKG_LIST_UNIQUE" ]] ; then
        rm /tmp/PKG_LIST_UNIQUE
        cat /tmp/PKG_LIST_UNIQUE_REVS | sort -u >> /tmp/PKG_LIST_UNIQUE || exit 1
        cat /tmp/PKG_LIST_UNIQUE_NOREVS | sort -u >> /tmp/PKG_LIST_UNIQUE || exit 1
else
        cat /tmp/PKG_LIST_UNIQUE_REVS | sort -u >> /tmp/PKG_LIST_UNIQUE || exit 1
        cat /tmp/PKG_LIST_UNIQUE_NOREVS | sort -u >> /tmp/PKG_LIST_UNIQUE || exit 1
fi

epkg autobuildpkgonly --skip-update $( cat /tmp/PKG_LIST_UNIQUE ) --keep-going y
