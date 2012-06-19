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

vo-config - utility functions for VO support configuration

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

=head1 OPTIONS

=head1 FUNCTIONS

=item get-fqans

=item get-vo-param


=cut

use strict;
use Getopt::Long;
use Config::IniFiles;

my $debug = 0;
my $vo = "";
my $fqan = "";

my $confdir = "/etc/vo-support";

sub print_usage() {
  print STDERR <<EOF;
Usage: $0 command [ arguments ]
Returns configuration data of supported VOs.

List of supported commands:

 get-fqans vo
    returns a list of configured FQANS of the given VO.

 get-vo-param fqan param
    return the value of the configuration parameter for
    the FQAN.

List of options:

 -d | --debug
    Turn on debugging. Print some diagnostic output, read
    configuration from the current directory instead of
    /etc/vo-support/.
EOF
}

GetOptions("debug" => \$debug) or do {
  print STDERR "Error parsing command line options";
  print_usage();
  die;
};

if ($debug) {
  print STDERR "Entering debugging mode. Configuration read from current directory.\n";
  $confdir = ".";
}


my $command = $ARGV[0] or do {
  print_usage();
  die;
};

my %conf = ();

sub readconf($) {
  my $vo = shift;
  tie %conf, 'Config::IniFiles', 
  (-file => "$confdir/$vo.conf", -fallback => "DEFAULT",
   -handle_trailing_comment => 1,
   -allowcontinue => 1) or
     do {
       print STDERR $_ foreach @Config::IniFiles::errors;
       die "Cannot read $confdir/$vo.conf, stopped"
     };
}

# get-fqans
# get the list of fqans
# arguments: vo name
sub get_fqans($) {
  my $vo = shift;
  my @fqans = (); # return value

  # go over the sections. If it looks like an FQAN, it *is* an FQAN.
  for my $section (keys %conf) {
    if ($section =~ m{^/[[:alpha:]]}) {
      push @fqans, $section
    }
  }
  return @fqans;
}

# get-vo-param
sub get_vo_param($$$) {
  my $vo = shift;
  my $fqan = shift;
  my $param = shift;
  if (!defined $conf{$fqan}) {
    die "Missing section [$fqan] in $vo.conf, stopped";
  }
  my $ret = $conf{$fqan}{$param};
  if (defined $ret) {
    return $ret;
  } else {
    return "undefined";
  }
}




SWITCH: {
  $command eq "get-fqans" && do {
    if ($#ARGV < 1) {
      print STDERR "Missing VO argument to $command";
      print_usage;
      die;
    }
    my $vo = $ARGV[1];
    readconf($vo);
    print join " ", get_fqans($vo);
    print "\n";
    last SWITCH;
  };

  $command eq "get-vo-param" && do {
    if ($#ARGV < 2) {
      print STDERR "Missing argument(s) to $command";
      print_usage;
      die;
    }
    $fqan = $ARGV[1];
    my $param = $ARGV[2];
    ($vo) = $fqan =~ m{^/([^/]+)} or die "Malformed FQAN: $fqan,";
    readconf($vo);
    print get_vo_param($vo, $fqan, $param) . "\n";
    last SWITCH;
  };

  print STDERR "unsupported command $command.";
  print_usage();
  die;
}


