#!/usr/bin/perl -w

use strict;

use XML::XPath;
use XML::XPath::XMLParser;

# Obtain the VoDump.xml file from the Operations Portal
# http://operations-portal.egi.eu/xml/voIDCard/public/all/true
my $doc = XML::XPath->new(filename => 'VoDump.xml');

my $nodes = $doc->find('//IDCard');

foreach my $idcard ($nodes->get_nodelist) {
  my $voname = $idcard->getAttribute("Name");
  printf "Found IDCard %s\n", $voname;
  my $change = $doc->findvalue("./LastChange", $idcard);
  print "Last Change: $change\n";

  my $description = $doc->findvalue("./Description", $idcard);
  # word wrap the description.
  # insert newline at the first white space after 68 chars.
  $description =~ s/\n/\n\n/g;
  $description =~ s/([^\n]{0,70})(?:\b\s*|\n|$)/$1\n/gi;

  my $version = "1.0";
  my $release = 1;


  open(my $specfile, ">", "SPECS/vo-$voname.spec")
    or die "cannot open SPECS/vo-$voname.spec for writing: $!";

  print $specfile <<EOSPEC;
Summary: Support for the $voname VO.
Name: vo-$voname
Version: $version
Release: $release
License: ASL 2.0
Group: System Environment/Base
URL: http://www.nikhef.nl/grid/
Requires: vo-support
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

%description
This package provides information regarding the
virtual organisation $voname.

$description

%prep

# Nothing to do.

%build

# Nothing to build

%install
rm -rf \$RPM_BUILD_ROOT

mkdir -p \$RPM_BUILD_ROOT/%{_datadir}/vo-support/vos/$voname/vomses

EOSPEC

  # Go over the VOMS servers to produce LSC file entries.
  my $vomsservers = $doc->find('.//VOMS_Server', $idcard);
  foreach my $vs ($vomsservers->get_nodelist) {
    my $vshostname = $doc->findvalue("./hostname", $vs);
    print "Found VOMS server: $vshostname\n";
    # The lsc file contains the DN of the server
    # followed by the DN of the CA
    my $serverdn = $doc->findvalue("./X509Cert/DN", $vs);
    my $servercadn = $doc->findvalue("./X509Cert/CA_DN", $vs);

    print $specfile <<EOSPEC;
cat > \$RPM_BUILD_ROOT/%{_datadir}/vo-support/vos/$voname/$vshostname.lsc <<EOF
$serverdn
$servercadn
EOF

EOSPEC

    # The vomses entries
    my $vomsesport = $vs->getAttribute("VomsesPort");
    print $specfile <<EOSPEC;
cat > \$RPM_BUILD_ROOT/%{_datadir}/vo-support/vos/$voname/vomses/$voname-$vshostname <<EOF
"$voname" "$vshostname" "$vomsesport" "$serverdn" "$voname"
EOF

EOSPEC
  }


  print $specfile <<EOSPEC;

mkdir -p \$RPM_BUILD_ROOT/%{_sysconfdir}/vo-support

%clean
rm -rf \$RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_datadir}/vo-support/vos/$voname

%post
# If there is no configuration file yet, install the basic
# one now.

if [ ! -e %{_sysconfdir}/vo-support/$voname.conf ]; then
    cat > \$RPM_BUILD_ROOT/%{_sysconfdir}/vo-support/$voname.conf <<EOF
# example configuration file for VO $voname
# Each FQAN has its own section

EOSPEC

  # Find all the FQANs of the VO
  my $fqans = $doc->find('.//FQANs/FQAN', $idcard);
  foreach my $fqan ($fqans->get_nodelist) {
    my $fqexpr = $doc->findvalue('./FqanExpr', $fqan);
    print $specfile <<EOSPEC;

[$fqexpr]

## set poolaccounts to the number of gridmapdir entries to create
## gridmapdir entries
#poolaccounts = 0

## Set poolprefix to the name of the pool accounts without the numeric tail
#poolprefix =

## Set groupmapping if this FQAN should be used in the groupmapfile
#groupmapping =

EOSPEC

  }

  print $specfile <<EOSPEC;
EOF
fi

if [ $1 -ge 1 ]; then
   if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
      . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
      add_vo $voname
   fi
fi

%preun
if [ $1 -eq 0 ]; then
   if [ -e /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh ]; then
      . /usr/share/vo-support/modules/rpm-scriptlet-helpers.sh
      remove_vo $voname
   fi
fi

%changelog

EOSPEC

  close($specfile);

}
