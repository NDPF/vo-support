#  File: vo-support/rpm-scriptlet-helpers.sh
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

# This module contains the helper functions to use in the %post and %preun
# scriptlets of the VO support RPMs. In fact, the following should
# suffice in the SPEC file (replace %{myvo} with the real VO name):

# %post
# if [ $1 -ge 1 ]; then
#    if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
#       . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
#       add_vo %{myvo}
#    fi
# fi
# 
# %preun
# if [ $1 -eq 0 ]; then
#    if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
#       . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
#       remove_vo %{myvo}
#    fi
# fi

# The base path of this script is where we find the other utilities of
# interest
scriptdir=`dirname $0`

# function add_vo() takes care of adding support for
# additional VOs. The names of the VOs are passed as arguments.
# For each VO all the registered triggers in
# /usr/share/vo-support/triggers/install/ is run. The triggers
# are run in normal unix sort order.
# Each trigger should accept 'add-vo' as a first argument
# and a (possibly empty) list of VOs as following arguments.

add_vo() {
    for i in `ls /usr/share/vo-support/triggers/install/` ; do
	if [ -x "/usr/share/vo-support/triggers/install/$i" ]; then
	    "/usr/share/vo-support/triggers/install/$i" add-vo "$@"
	fi
    done
}

# function remove_vo() takes care of removing support for
# VOs. The names of the VOs are passed as arguments.
# For each VO all the registered triggers in
# /usr/share/vo-support/triggers/remove/ is run. The triggers
# are run in normal unix sort order.
# Each trigger should accept 'remove-vo' as a first argument
# and a (possibly empty) list of VOs as following arguments.

remove_vo() {
    for i in `ls /usr/share/vo-support/triggers/remove/` ; do
	if [ -x "/usr/share/vo-support/triggers/remove/$i" ]; then
	    "/usr/share/vo-support/triggers/remove/$i" remove-vo "$@"
	fi
    done
}

# function add_trigger() runs a trigger for all VOs. Use this
# in the %post script for a trigger package like so:
# %post
# if [ $1 -ge 1 ]; then
#    if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
#       . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
#       add_trigger MYTRIGGER
#    fi
# fi
# 
# The argument is the name of the trigger to add.
add_trigger() {
    vos=`ls /usr/share/vo-support/vos/`
    test ! -z "$vos" || return 0
    test ! -z "$1" || return 1
    if [ -x /usr/share/vo-support/triggers/install/$1 ]; then
	/usr/share/vo-support/triggers/install/$1 add-vo $vos
    fi
}

# function remove_trigger() runs a trigger for all VOs. Use
# in the %preun scriptlet in the spec file of a trigger package:
# %preun
# if [ $1 -eq 0 ]; then
#    if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
#       . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
#       remove_trigger MYTRIGGER
#    fi
# fi
# The argument is the name of the trigger to remove.
remove_trigger() {
    vos=`ls /usr/share/vo-support/vos/`
    test ! -z "$vos" || return 0
    test ! -z "$1" || return 1
    if [ -x /usr/share/vo-support/triggers/remove/$1 ]; then
	/usr/share/vo-support/triggers/remove/$1 remove-vo $vos
    fi
}

vo_config() {
    if [ -x "$scriptdir/vo-config" ]; then
	"$scriptdir/vo-config" "$@"
    else
	echo "$scriptdir/vo-config is missing, aborted" >&2
	exit 2
    fi
}
