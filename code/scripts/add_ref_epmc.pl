#!/usr/bin/env perl

use strict;
use warnings;
use LWP::Simple;
use JSON;
use DDP;

my $pmid = 12636087;
my $url = "http://www.ebi.ac.uk/europepmc/webservices/rest/search?format=json&query=ext_id:$pmid";

my $content = get($url);

my $ref = from_json($content);
p($ref);

#RN  1
#RM  12636087
#RT  The biosynthesis of shikimate metabolites.
#RA  Knaggs AR;
#RL  Nat Prod Rep. 2003;20:119-136.

foreach my $refObj (@{$ref->{resultList}->{result}}){
  next unless $refObj->{pmid} == $pmid;
  p($refObj);
  $refObj->{authorString} =~ s/(\.)$//;
  print "RN  [1]\n";
  print "RM  ".$refObj->{pmid}."\n";
  print "RT  ".$refObj->{title}."\n";
  print "RA  ".$refObj->{authorString}.";\n";
  print "RL  ".$refObj->{journalTitle}.". ".$refObj->{pubYear}.";".$refObj->{journalVolume}.":".$refObj->{pageInfo}.".\n";
}
