#/bin/sh
#  File: vo-support-vomsdir/gridmapdir.sh
#  Author: Dennis van Dok <dennisvd@nikhef.nl>
#
#  Copyright 2012  Stichting FOM
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# This script is installed as a trigger in
# /usr/share/vo-support/triggers/install/gridmapdir.sh and
# /usr/share/vo-support/triggers/remove/gridmapdir.sh

# It is normally run by %post or %preun scriptlets in RPM packages
# for each installed VO. The first argument is the main command.
# Commands understood by this script are:
#     add-vo [list of VOs to add]
#     remove-vo [list of VOs to remove]
#
# Other commands are silently ignored. The list of VOs may be empty.
#
# The add-vo command will add the VO's FQAN mapping rule to
# /etc/grid-security/voms-mapfile and /etc/grid-security/groupmapfile.
# The configuration parameters in 
# /etc/vo-support/$vo.conf
# are poolprefix and groupmapping.

# The remove-vo will uninstall these files.

# installation variable
sbindir=@sbindir@

printusage() {
    cat >&2 <<EOF
Usage: $prg command [ VO ... ]

Valid commands:

 add-vo     add grid-mapfile entries for given VOs
     
 remove-vo  remove grid-mapfile entries for given VOs

EOF
}

if [ $# -lt 1 ] ; then
    echo "$0 requires a command" >&2
    printusage
    exit 1
fi

gridmapfile=/etc/grid-security/voms-grid-mapfile
groupmapfile=/etc/grid-security/groupmapfile

cmd="$1"
shift

# $1 = VO
# $2 = add/remove
update_mapfiles() {
    for fqan in `${sbindir}/vo-config get-fqans $1` ; do
	poolprefix=`${sbindir}/vo-config get-vo-param "$fqan" poolprefix`
	groupmapping=`${sbindir}/vo-config get-vo-param "$fqan" groupmapping`
	test "$groupmapping" != undefined || continue
	if [ $2 = add ]; then
	    # add the FQAN to the mapfiles
	    # if it's not already there
	    if test "$poolprefix" != undefined &&
		! grep -qF "\"$fqan\" " $gridmapfile ; then
		echo "\"$fqan\" .$poolprefix" >> $gridmapfile
	    fi
	    if test "$groupmapping" != undefined &&
		! grep -qF "\"$fqan\" " $groupmapfile ; then
		echo "\"$fqan\" $groupmapping" >> $groupmapfile
	    fi
	else # remove
	    # remove the FQAN from the mapfiles
	    if test "$poolprefix" != undefined && 
		grep -qF "\"$fqan\" " $gridmapfile ; then
		sed "\\@\"$fqan\"@ d" $gridmapfile > $gridmapfile.new
		mv $gridmapfile.new $gridmapfile
	    fi
	    if test "$groupmapping" != undefined && 
		grep -qF "\"$fqan\" " $groupmapfile ; then
		sed "\\@\"$fqan\"@ d" $groupmapfile > $groupmapfile.new
		mv $groupmapfile.new $groupmapfile
	    fi
	fi
    done
}


case "$cmd" in
    add-vo)
	for vo in "$@" ; do
	    update_mapfiles $vo add
	done
	;;
    remove-vo)
	for vo in "$@" ; do
	    update_mapfiles $vo remove
	done
	;;
    *)
	echo "Unknown command $cmd" >&2
	printusage
	exit 1
	;;
esac

