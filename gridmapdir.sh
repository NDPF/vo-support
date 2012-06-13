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
# The add-vo command will install the VO's pool account entries
# in /etc/grid-security/gridmapdir according to the configuration
# file in /etc/vo-support/$vo.conf
#
# The remove-vo will uninstall these files.

if [ $# -lt 1 ] ; then
    echo "$0 requires a command" >&2
    exit 1
fi

gridmapdir=/etc/grid-security/gridmapdir
vosdir=/usr/share/vo-support/vos

cmd="$1"
shift

# $1 = VO
# $2 = add/remove
update_gridmapdir() {
    if [ ! -d $gridmapdir ]; then
	mkdir -P $gridmapdir
    fi

    # for each FQAN in this VO
    #     get the poolaccounts parameter
    #     if poolaccounts > 0, then
    #         get the poolprefix
    #             touch each poolname that doesn't exist for adding
    #             remove each poolname if link count = 1.

    for fqan in `vo-config get-fqans $1` ; do
	poolaccounts=`vo-config --fqan "$fqan" get-vo-param poolaccounts`
	poolprefix=`vo-config --fqan "$fqan" get-vo-param poolprefix`
	if [ $poolaccounts -gt 0 -a -n "$poolprefix" ]; then
	    i=0
	    while [ $i -lt $poolaccounts ]; do
		poolaccount=$gridmapdir/`printf "$poolprefix%03i" $i`
		if [ -e $poolaccount ] ; then
		    if [ $2 = remove ]; then
			# only remove pool account not currently in use
			linkcount=`stat --format '%h' $poolaccount`
			if [ $linkcount -eq 1 ]; then
			    # be aware there is a race condition here.
			    # The link count may change before the removal
			    rm $poolaccount
			fi
		    fi
		else # file does not exists
		    if [ $2 = add ]; then
		    	touch $poolaccount
		    fi
		fi
		i=$(($i+1))
	    done
	fi
    done
}


case "$cmd" in
    add-vo)
	for vo in "$@" ; do
	    update_gridmapdir $vo add
	done
	;;
    remove-vo)
	for vo in "$@" ; do
	    update_gridmapdir $vo remove
	done
	;;
esac

