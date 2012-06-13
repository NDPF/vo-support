#  File: vo-support/vo-support.spec
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

Summary: Virtual Organisation support for Grid services
Name: vo-support
Version: 0.2
Release: 1
License: APL 2.0
Group: System Environment/Base
URL: http://www.nikhef.nl/grid
Source: %{name}-%{version}.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%package vomsdir
Summary: Generate vomsdir data for supported VOs
Group: System Environment/Base
Requires: %{name}

%package vomses
Summary: Install vomses information for supported VOs
Group: System Environment/Base
Requires: %{name}

%package gridmapdir
Summary: Install gridmapdir entries for supported VOs
Group: System Environment/Base
Requires: %{name}

%description
Virtual Organisations (VOs) are groups of people, often research
groups, with access to shared computing resources. Structure and
membership management is arranged within framework organisations such
as EGI (the European Grid Infrastructure). As access to Grid resources
is through VO membership only, the site administrators have to deal
with setting up VO-specific elements particular to each service to
configure. The vo-support package helps to streamline the
configuration by providing a dynamic, pluggable structure where
individual VO packages can register details per VO, and individual
grid services can register install hooks that act on all installed
VOs.


%description vomsdir
This vo-support trigger installs the LSC files of supported
VOs in the proper location for use by authorization libraries.

Grid users coming from Virtual Organisations authenticate
using VOMS proxies; the VOMS attributes in these proxies are
signed by a VOMS server of their VO. The trust association is
arranged through LSC files which contain the DN of the VOMS server
and the DN of the CA that signed the server certificate.


%description vomses
This vo-support trigger installs the 'vomses' information for
supported VOs in /etc/vomses/. This information is used
by voms-proxy-init to determine which VOMS service endpoint
to contact.

%description gridmapdir
This vo-support trigger installs gridmapdir entries
for supported VOs in /etc/grid-security/gridmapdir. The VO
configuration in /etc/vo-support/ lists the supported
FQANS, their pool prefixes and the number pool accounts
to create.

%prep
%setup -q

%build

make

%install
rm -rf $RPM_BUILD_ROOT

make DESTDIR=$RPM_BUILD_ROOT install

mkdir -p $RPM_BUILD_ROOT/%{_datadir}/%{name}/vos

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_datadir}/%{name}/modules
%{_sbindir}/vo-config
%dir %{_datadir}/%{name}/vos
%dir %{_datadir}/%{name}/triggers/install
%dir %{_datadir}/%{name}/triggers/remove

%files vomsdir
%defattr(-,root,root,-)
%{_datadir}/vo-support/triggers/install/vomsdir.sh
%{_datadir}/vo-support/triggers/remove/vomsdir.sh

%files vomses
%defattr(-,root,root,-)
%{_datadir}/vo-support/triggers/install/vomses.sh
%{_datadir}/vo-support/triggers/remove/vomses.sh

%files gridmapdir
%defattr(-,root,root,-)
%{_datadir}/vo-support/triggers/install/gridmapdir.sh
%{_datadir}/vo-support/triggers/remove/gridmapdir.sh


%post vomsdir
# add all VOs currently supported
if [ $1 -ge 1 ]; then
   if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
      . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
      add_trigger vomsdir.sh
   fi
fi

%preun vomsdir
# remove all VOs currently supported
if [ $1 -eq 0 ]; then
   if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
      . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
      remove_trigger vomsdir.sh
   fi
fi


%post vomses
# add all VOs currently supported
if [ $1 -ge 1 ]; then
   if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
      . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
      add_trigger vomses.sh
   fi
fi

%preun vomses
# remove all VOs currently supported
if [ $1 -eq 0 ]; then
   if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
      . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
      remove_trigger vomses.sh
   fi
fi


%post gridmapdir
# add all VOs currently supported
if [ $1 -ge 1 ]; then
   if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
      . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
      add_trigger gridmapdir.sh
   fi
fi

%preun gridmapdir
# remove all VOs currently supported
if [ $1 -eq 0 ]; then
   if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
      . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
      remove_trigger gridmapdir.sh
   fi
fi


%changelog
* Wed Jun 13 2012 Dennis van Dok <dennisvd@nikhef.nl> 0.2-1
- Added gridmapdir module and vo-config.pl script
- Install the vo-config script in sbindir

* Mon May 14 2012 Dennis van Dok <dennisvd@nikhef.nl> 0.1-1
- Initial build.


