#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use File::Slurp;
use DDP;

#my @files = qw(JSON_4558 JSON_83333);

opendir(DIR, ".");
my @files = grep{ $_ ne "." && $_ ne ".."} readdir(DIR);
my $merged;

foreach my $f (@files){
  next if($f !~ /JSON/);
  print "$f\n";
  my $j = read_file( $f );
  if(!defined($merged)){
    $merged = from_json( $j );
  }else{
    my $toMerge = from_json( $j );
    foreach my $gp (keys %{$toMerge}){
      #print $gp;      
      if(!$merged->{$gp}){
        die "$gp not found in first file\n";
      }else{
        for(my $i = 0; $i <= $#{$toMerge->{$gp}->{steps}}; $i++){
          my $step = $toMerge->{$gp}->{steps}->[$i];
          foreach my $valKey (keys %{$step->{values}}){
            $merged->{$gp}->{steps}->[$i]->{values}->{$valKey} = $step->{values}->{$valKey};  
            #print $step->{values}->{$valKey};  
          }
        }
      }
      foreach my $key (keys %{ $toMerge->{$gp}->{values} }){
        if($key eq 'TOTAL'){
          foreach my $sKey (keys %{ $toMerge->{$gp}->{values}->{TOTAL} }){
            $merged->{$gp}->{values}->{TOTAL}->{$sKey} += $toMerge->{$gp}->{values}->{TOTAL}->{$sKey};
          }
        }else{
          $merged->{$gp}->{values}->{$key} = $toMerge->{$gp}->{values}->{$key};
        }
      }
    }
  }
}

my $mergedJ = to_json($merged, {ascii => 1});

write_file('JSON_MERGED', $mergedJ);

