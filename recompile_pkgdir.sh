#!/bin/bash
# Author & Copyright holder: Rogentos Team, 2018
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

# updating portage structures before any action taken
epkg update

# nothing else than category packages should be here
# if there is something else, please make sure you exclude it
for d in $( ls | sed -e '/Packages/d' ) ; do

	cd $d

	for i in $( ls | grep tbz2 | sed -e 's/.tbz2//g' ) ; do

		export local_pwd=$d
		export local PKGDIR_COUNT_LSTDIR="${local_pwd%"${local_pwd##*[!/]}"}"
        	export local PKGDIR_COUNT_LSTDIR=${PKGDIR_COUNT_LSTDIR##*/}

		if [[ -z $(qlist -Iv | grep $( echo $PKGDIR_COUNT_LSTDIR)/$i ) ]] ; then
			epkg autobuildpkgonly --skip-update =$( echo $PKGDIR_COUNT_LSTDIR)/$i --keep-going y
		fi
	done

	cd ../
done
