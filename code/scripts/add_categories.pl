#!/usr/bin/env perl

use strict;
use warnings;
use File::Copy;
use File::Slurp;

use GenomeProperties;
use GenomePropertiesIO;
my $options = {};
my %cats;
$options->{status} = "checked_and_public";

my $gp = GenomeProperties->new;

open(C, "<", "category_relationships") or die "Could not open category_relationships";
while(<C>){
  my($parent, $child) = split(/\s+/, $_);
  push(@{$cats{$parent}}, $child);
}

#Read the parent file in.
foreach my $dir (sort keys %cats){
	print "$dir\n";
  next if(-e "$dir/done.cat");
  eval{
    GenomePropertiesIO::parseDESC("$dir/DESC", $gp, $options);
  };

  if($@){
    print STDERR "$dir: does not pass check $@\n";
    open(E, ">", "$dir/error");
    print E "Error parsing DESC:\n $@\n";
    close(E);
  }
  my $pgp = $gp->get_def($dir);
  
  # Copy the DESC file sideways
  copy("$dir/DESC","$dir/DESC.ori") or die "Copy of DESC failed: $!";

  #Add the child steps.
  my $stepNumber = 0;
  my $required   = 0;
  #--
  #SN  1
  #ID  Aferr subtype specific proteins
  #RQ  0
  #EV  IPR017545; TIGR03114;

  my $skipped;
  my @desc = read_file("$dir/DESC");
  foreach my $child (@{$cats{$dir}}){
    if(defined($options->{status}) and ! GenomePropertiesIO::_checkStatus($child, $options)){
      $skipped .= "$child ";
      next;
    }
    #read in the child ste
    GenomePropertiesIO::parseDESC("$child/DESC", $gp, $options);
    my $cgp = $gp->get_def($child);
    my $desc = $cgp->name;
    $stepNumber++;
    #print "SN $stepNumber, ID $desc, RQ $required, EV $child\n";
    my $index = $#desc;
    #This will replace final // with --
    $desc[$index] = "--\n";
    $index++;
    $desc[$index] = "SN  $stepNumber\n";
    $index++;
    $desc[$index] = "ID  $desc\n"; 
    $index++;
    $desc[$index] = "RQ  $required\n";
    $index++;
    $desc[$index] = "EV  $child;\n";
    $index++;
    $desc[$index] = "//\n"
  }
  
  #Now write out the DESC.
  write_file("$dir/DESC", @desc);
  open(F,">", "$dir/done.cat");
  print F "$skipped\n" if($skipped);
  close(F);
}
