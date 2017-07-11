#!/usr/bin/env perl

use strict;
use warnings;
use File::Slurp;


my $file = shift;

my @contents = read_file($file);

foreach my $line (@contents){
  chomp($line);
  #Currently columns F/G contain the status. 
  my @cols = split(/\t/, $line);
  if($cols[0] !~ /GenProp\d{4}/){
    die "Failed fo get GenProp accession from $cols[0] in $line\n";
  }
  if($cols[5] !~ /1|0/){
    die "Failed fo get GenProp accession from $cols[0] in $line\n";
  }
  if($cols[6] !~ /1|0/){
    die "Failed fo get GenProp accession from $cols[0] in $line\n";
  }
  
  $cols[0] =~ s/\///;
  $cols[0] =~ s/\s+//g;
  $cols[6] =~ s/\r//g;
  if(!-d $cols[0]){
    die "Can not find directory for |$cols[0]|\n";
  }
  
  open(S, ">", "$cols[0]/status") or die "Could not open status file for $cols[0]\n";
  print S "checked:\t$cols[5]\n";
  print S "public:\t$cols[6]\n";
  print S "--\n";
  close(S);
}
