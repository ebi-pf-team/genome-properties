#!/usr/bin/perl

use strict;
use warnings;
use DDP;
use File::Slurp;

open(P, '<', "pathway_info_formatted.txt") or die;
$/="//";
my @p;
while(<P>){
  push(@p, $_);
}
close(P);
$/="\n";



for (my $i =0; $i < $#p; $i++){
  my ($acc) = $p[$i]=~/AC (\S+)/;
  my @entry = split(/\n/, $p[$i]);
  for(my $j = 0; $j <= $#entry; $j++){
    $entry[$j] =~ s/^(\S{2})(\s)/$1  /;
    $entry[$j].="\n";;
  }
  if($entry[0] !~ /\S+/){
    shift(@entry);
  }
  if(!-d "/tmp/GPMc/$acc"){
    mkdir("/tmp/GPMc/$acc") || die "Could not make dir /tmp/GPMc/$acc\n";
  }
  open(S, '>', "/tmp/GPMc/$acc/status") or die "Could not open status file:[$!]\n";
  print S "checked:\t0\npublic:\t0\n--\n";
  close(S);
  print "|$acc|\n";
  write_file("/tmp/GPMc/$acc/DESC", @entry);
}


