#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use DDP;
use Text::Wrap;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );

my $pmid = shift;
exit unless($pmid);
my $url = "https://www.ebi.ac.uk/europepmc/webservices/rest/search?format=json&query=ext_id:$pmid";



my $content;
my $response = $ua->get($url);
if ( $response->is_success ) {
  $content = $response->decoded_content;
} else {
  die $response->status_line;
}


my $ref = from_json($content);

#RN  1
#RM  12636087
#RT  The biosynthesis of shikimate metabolites.
#RA  Knaggs AR;
#RL  Nat Prod Rep. 2003;20:119-136.

$Text::Wrap::unexpand = 0;
$Text::Wrap::columns = 76;
foreach my $refObj (@{$ref->{resultList}->{result}}){
  next unless $refObj->{pmid} == $pmid;
  $refObj->{authorString} =~ s/(\.)$//;
  print "RN  [1]\n";
  print "RM  ".$refObj->{pmid}."\n";
  print wrap("RT  ", "RT  ", $refObj->{title});
  print "\n";

  print wrap("RA  ", "RA  ", $refObj->{authorString}.";");
  print "\n";

  print wrap("RL  ", "RL  ", $refObj->{journalTitle}.". ".$refObj->{pubYear}.";".$refObj->{journalVolume}.":".$refObj->{pageInfo});
  print "\n";
}
