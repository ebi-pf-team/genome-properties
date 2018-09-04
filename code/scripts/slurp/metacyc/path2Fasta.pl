#!/usr/bin/env perl
$|=1;
use strict;
use warnings;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );

open(F, "<", "pathway_info.txt") or die;


my ($pathway, $sn, $fastas);
while(<F>){
  if(/PATHWAY: (\S+)/){
    if($pathway){
      open(FA, ">", "/tmp/GPMc/$pathway/FASTA") or die;
      print FA $fastas;
      close(FA);
    }
    $pathway = $1;    
    $sn = 0;
    $fastas='';
  }
  
  #Reaction RXN-11361: O95396 P12282 -> RXN-12473
  elsif(/^\s+Reaction \S+:(.*\S.*)\-\>/){
    my $accString = $1;
    $sn++;
    my @accs = $accString =~ /\S+/g;
    my ($success, $fasta);
    foreach my $acc (@accs){
      ($success, $fasta) = getFasta($acc, $sn);
      last if($success)
    }
    $fastas .= $fasta;
    #print "Pathway $pathway - $sn, |$fasta|\n";
  }elsif(/^\s+Reaction/){
    $sn++;
    #print "Pathway $pathway - $sn, ||\n";
  }
}


sub getFasta {
  my($acc, $sn) = @_;

  my $url = "http://www.uniprot.org/uniprot/$acc.fasta";
  my $response = $ua->get($url);
  my $success = 0;;
  my $fasta;
  if ( $response->is_success ) {
    $fasta = $response->decoded_content;
    $success =1;
  } else {
    warn "$acc not matched\n";
    $fasta = ">$acc NOT MATCHED\n";
  }
  $fasta =~ s/^(>\S+)/$1 \(Step num\: $sn\)/;
  return($success, $fasta);
}

