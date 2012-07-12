#!/usr/bin/perl -w

use strict;

use XML::XPath;
use XML::XPath::XMLParser;

my $doc = XML::XPath->new(filename => 'VoDump.xml');

my $nodes = $doc->find('//IDCard');

foreach my $idcard ($nodes->get_nodelist) {
  printf "Found IDCard %s\n", $idcard->getAttribute("Name");
  my $change = $doc->findvalue("./LastChange", $idcard);
  print "Last Change: $change\n";
}


