#  File: vo-support/maintainerscript-helpers.sh
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
#    if [ -e /usr/share/vo-support/scriptlets/maintainerscript-helpers.sh ]; then
#       . /usr/share/vo-support/scriptlets/maintainerscript-helpers.sh
#       configure_vo %{myvo}
#    fi
# fi
# 
# %preun
# if [ $1 -eq 0 ]; then
#    if [ -e /usr/share/vo-support/scriptlets/maintainerscript-helpers.sh ]; then
#       . /usr/share/vo-support/scriptlets/maintainerscript-helpers.sh
#       deconfigure_vo %{myvo}
#    fi
# fi

# The base path of this script is where we find the other utilities of
# interest
scriptdir=`dirname $0`

# function configure_vo() takes care of configuring the system by
# running each support module for the VOs given as arguments.
configure_vo() {
    vo-support configure-vo "$@"
}

# function deconfigure_vo() takes care of removing support for the VOs
# passed as arguments.
deconfigure_vo() {
    vo-support deconfigure-vo "$@"
}

# function add_module() runs a module for all configured VOs. Use this
# in the %post script for a module package like so:
# %post
# if [ $1 -ge 1 ]; then
#    if [ -e /usr/share/vo-support/scriptlets/maintainerscript-helpers.sh ]; then
#       . /usr/share/vo-support/scriptlets/maintainerscript-helpers.sh
#       add_module MYMODULE
#    fi
# fi
# 
# The argument is the name of the module to add.
add_module() {
    vo-support add-module $1
}

# function remove_module() runs a module for all VOs. Use
# in the %preun scriptlet in the spec file of a module package:
# %preun
# if [ $1 -eq 0 ]; then
#    if [ -e /usr/share/vo-support/scriptlets/maintainerscript-helpers.sh ]; then
#       . /usr/share/vo-support/scriptlets/maintainerscript-helpers.sh
#       remove_module MYMODULE
#    fi
# fi
# The argument is the name of the module to remove.
remove_module() {
    vo-support remove-module $1
}

vo_config() {
    if [ -x "$scriptdir/vo-config" ]; then
	"$scriptdir/vo-config" "$@"
    else
	echo "$scriptdir/vo-config is missing, aborted" >&2
	exit 2
    fi
}
