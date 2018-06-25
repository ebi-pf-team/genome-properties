#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use DDP;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );

my ($repoURL, $help);

GetOptions( "r|repo=s" => \$repoURL, "h|help" => \$help) or die "Invalid option\n";

help() if($help);
die if(!$repoURL);

if($repoURL !~ /\/data$/){
  die "Please check your URL, expected the genome properties data directory\n";
}

my $content;
my $response = $ua->get($repoURL);
if ( $response->is_success ) {
  $content = $response->decoded_content;
} else {
  die $response->status_line;
}

my @gps = $content =~ /GenProp(\d{4})/g;
my @nextAcc;

foreach my $acc (@gps){
  $nextAcc[$acc] = 1;
}

for (my $i=1106; $i<=scalar(@nextAcc); $i++){
  if(!$nextAcc[$i]){
    print "Next accession GenProp".sprintf("%04d", $i)."\n";
    last;
  }
}

sub help{

  print "usage: $0 -repo https://github.com/ebi-pf-team/genome-properties/tree/rel2.0/data\n";
  exit;

}
