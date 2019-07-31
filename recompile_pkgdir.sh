#!/bin/bash
# Author & Copyright holder: Rogentos Team, 2018-2019
# LICENSE: GPL v2
# This script recompiles simple packages which
# are not installed on the system, and are present in $PKGDIR

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
for d in $( echo $PKG_FIND_LS_CMD ) ; do

	if [[ -d "$d" ]] ; then
		cd $d

		for i in $( ls | grep tbz2 | sed -e 's/.tbz2//g' ) ; do

			export local_pwd=$d
			export local PKGDIR_COUNT_LSTDIR="${local_pwd%"${local_pwd##*[!/]}"}"
			export local PKGDIR_COUNT_LSTDIR="${PKGDIR_COUNT_LSTDIR##*/}"

			if [[ -z $(qlist -Iv | grep $( echo $PKGDIR_COUNT_LSTDIR)/$i ) ]] ; then
				epkg autobuildpkgonly --skip-update =$( echo $PKGDIR_COUNT_LSTDIR)/$i --keep-going y
			fi
		done

		cd ../
	else
		echo -e "$d is not a folder. Skipping.."
	fi
done
