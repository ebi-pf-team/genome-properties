#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use DDP;

use GenomePropertiesIO;

my @dirs;
my $recursive = 1;
my $all;

GetOptions ( "recursive=i" => \$recursive,
             "gp=s"        => \@dirs,
             "all"         => \$all ) or die;

if($all){
  opendir(D, ".");
  @dirs = grep{ $_ =~ /GenProp\d{4}/}readdir(D);
  closedir(D);
}

my $dir= shift;
my $gp = GenomeProperties->new;
GenomePropertiesIO::validateGP(\@dirs, $gp, $recursive);
