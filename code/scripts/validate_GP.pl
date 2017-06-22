#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

use GenomePropertiesIO;

my @dirs;
my $recursive = 1;
my $all;
$| = 1;
GetOptions ( "recursive=i" => \$recursive,
             "gp=s"        => \@dirs,
             "all"         => \$all ) or die;

if($all){
  opendir(D, ".");
  @dirs = sort {$a cmp $b } grep{ $_ =~ /GenProp\d{4}/}readdir(D);
  closedir(D);
}

my $gp = GenomeProperties->new;
GenomePropertiesIO::validateGP(\@dirs, $gp, $recursive);
