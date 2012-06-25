#!/usr/bin/perl -w

# Copyright 2012 Stichting FOM
#
#     Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This program implements a set of utility functions that may be
# used by maintainer scripts for VO support purposes

=head1 NAME

vo-config - utility to parse VO support configuration

=head1 SYNOPSIS

vo-config [ B<options> ] command I<arguments>

=head2 Commands

=over

=item get-fqans I<vo>

Print a whitespace-separated list of FQANS configured
for the VO.

=item get-vo-param { I<vo> | I<fqan> } I<param>

Print the configuration parameter associated with
the VO or FQAN.

=back

=head2 Options

=over

=item B<-d>, B<--debug>

Enter debugging mode.

=item B<-h>, B<--help>

Print help.

=back

=head1 DESCRIPTION

This utility prints configuration data for Virtual Organisations (VOs)
as set in INI files in /etc/vo-support/. It's intended to be used as a
shell script helper, because parsing INI files in shell scripts is
hard. It does not have the ability to write or change configuration
files.

The VO configuration is stored in files under /etc/vo-support/. Each VO
has a single configuration file named after the VO and with a ".conf"
extension. For example the pvier VO is configured in

    /etc/vo-support/pvier.conf

The format of the configuration file is in INI style; it contains a
number of sections with names written between brackets ('[' and ']').
Each section lists key/value pairs. E.g.:

    field0 = this is a global parameter for the pvier VO
    [/pvier]
    # This is a comment
    field1 = value
    SomeParameter = This is a valid value
    [/pvier/group1]
    field1 = some other value

White space around the '=' is optional. You should not use quotes unless they need
to be part of the value.

Any parameters given before the first section header are considered to be
part of the [DEFAULT] section and global to the VO. The [DEFAULT] section
header may be omitted.

=head2 Commands

=over

=item get-fqans I<vo>

This command retrieves the list of FQANS for the given VO. These are the section
headers in the I<vo>.conf file, with the exception of the DEFAULT section. The
resulting list is printed and STDOUT separated by white space.

=item get-vo-param { I<vo> | I<fqan> } I<param>

This command retrieves a specific parameter for the given VO or FQAN. If an FQAN is
given (i.e. it the argument has a leading '/'), then the VO is derived from the
first element after the '/'. If the section or parameter is not found in the
configuration file, the value 'undefined' is printed.

If a VO is given, then the parameter is retrieved from the DEFAULT section of the
configuration file.

=back

=head1 OPTIONS

This utility accepts the following option:

=over

=item B<-d>, B<--debug>

Enter debugging mode. The configuration is read from the current directory
instead of /etc/vo-support/ and more diagnostic output may be printed to
STDERR.

=item B<-h>, B<--help>

Print this extended help text.

=back

=cut

use strict;
use Getopt::Long;
use Pod::Usage;
use Site::Configuration::VO;

my $debug = 0;
my $help = 0;
my $vo = "";
my $fqan = "";

my $confdir = "/etc/vo-support";

GetOptions("debug" => \$debug,
	   "help" => \$help) or do {
  pod2usage("Error parsing command line options.\n");
};

if ($help) {
  pod2usage(-verbose => 2, -exitval => 0);
}

my $voconf = Site::Configuration::VO->new();

if ($debug) {
  print STDERR "Entering debugging mode. Configuration read from current directory.\n";
  $confdir = ".";
  $voconf->confdir(".");
}


my $command = $ARGV[0] or do {
  pod2usage("$0 requires a command.\n");
};

my $exitval = 0;

SWITCH: {
  $command eq "get-fqans" && do {
    if ($#ARGV < 1) {
      pod2usage(print STDERR "Missing VO argument to $command.\n");
    }
    my $vo = $ARGV[1];
    check_voname($vo);
    print join " ", $voconf->get_fqans($vo);
    print "\n";
    last SWITCH;
  };

  $command eq "get-vo-param" && do {
    if ($#ARGV < 2) {
      pod2usage("Missing argument(s) to $command.\n");
    }
    $fqan = $ARGV[1];
    my $param = $ARGV[2];

    if ($fqan =~ m{^/([^/]+)}) {
      $vo = $1;
    } else {
      $vo = $fqan;
      $fqan = "DEFAULT";
    }
    check_voname($vo);
    my $val = $voconf->get_vo_param($vo, $param, $fqan);
    if (! defined $val) { $val = "undefined"; $exitval = 1; }
    print $val . "\n";
    last SWITCH;
  };
  pod2usage("unsupported command $command.\n");
}

exit $exitval;

sub check_voname {
  for (@_) {
    die "Illegal VO name '$_'" if /[^\w.-]/;
  }
}

__END__


=head1 EXIT CODE

=over

=item 0

On success

=item 1

The requested item wasn't found. This helps to disambiguate between
an undefined parameter and a parameter that is explicitly set to the
string "undefined".

=item 2

A fatal error occurred; either a command-line error or a corrupt
configuration file.

=back

=head1 DIAGNOSTICS


=over

=item Illegal VO name '%s'

VO names may only contain letters, numbers, underscores, dots and dashes.

=back

=head1 FILES

=over

=item /etc/vo-support/*.conf

=back

=head1 AUTHOR

vo-config was written by Dennis van Dok <dennisvd@nikhef.nl>.

Please report bugs and feature requests to C<grid-mw-security-support at nikhef.nl>.

=head1 SEE ALSO

L<Site::Configuration::VO>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 Stichting FOM

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


