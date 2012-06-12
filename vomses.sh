#/bin/sh
#  File: vo-support-vomsdir/vomses.sh
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
# /usr/share/vo-support/triggers/install/vomses.sh and
# /usr/share/vo-support/triggers/remove/vomses.sh

# It is normally run by %post or %preun scriptlets in RPM packages
# for each installed VO. The first argument is the main command.
# Commands understood by this script are:
#     add-vo [list of VOs to add]
#     remove-vo [list of VOs to remove]
#
# Other commands are silently ignored. The list of VOs may be empty.
#
# The add-vo command will install the VO's vomses entries in
# /etc/vomses/ my making symbolic links to whatever is in
#  /usr/share/vo-support/vos/$vo/vomses/*
#
# The remove-vo will remove files that match
# /etc/vomses/vo-*

if [ $# -lt 1 ] ; then
    echo "$0 requires a command" >&2
    exit 1
fi

vosdir=/usr/share/vo-support/vos
vomsesdir=/etc/vomses

cmd="$1"
shift

add_vo_to_vomses() {
    if [ -d "$vosdir/$1/vomses" ]; then
	for i in "$vosdir/$1/vomses"/* ; do
	    if [ ! -e $vomsesdir/`basename "$i"` ]; then
		ln -s "$i" $vomsesdir/
	    fi
	done
    fi
}

remove_vo_from_vomses() {
    rm -f $vomsesdir/"$1"-*
}

case "$cmd" in
    add-vo)
	test -d "$vomsesdir" || mkdir -p "$vomsesdir"
	for vo in "$@" ; do
	    add_vo_to_vomses "$vo"
	done
	;;
    remove-vo)
	for vo in "$@" ; do
	    remove_vo_from_vomses "$vo"
	done
	;;
esac

