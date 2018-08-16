#!/usr/bin/env perl
$|=1;
use strict;
use warnings;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );

open(F, "<", "pathway_info.txt") or die;


my %tree;

my ($pathway, $sn, $fastas);
while(<F>){
  if(/PATHWAY: (\S+)/){
    $pathway = $1;    
  }
  elsif(/Predecessor Pathway\(s\)\: $/){
    #print "$_\n";
    $tree{ $pathway } = [];  
  }
  elsif(/Predecessor Pathway\(s\)\: (.*)$/){
    my $subs = $1;
    my ($bit, @children) = split(/\s+/, $subs);
    foreach my $c (@children){
      push (@{$tree{$pathway}}, $c);
    }
  }
}
use DDP;
p(%tree);
open(C, ">", "children.txt");
foreach my $p (keys %tree){
  my $indent = "";
  printTree($indent, $p, \%tree);
}
close(C);
exit;


sub printTree {
  my ($i, $p, $t) = @_;
  print "$i$p\n";
  $i.="\t";
  foreach my $c (@{$t->{$p}}){
    printTree($i, $c, $t);
  } 
  if(scalar(@{$t->{$p}}) == 0){
    print C "$p\n";
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

