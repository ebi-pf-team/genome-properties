#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Slurp;

use GenomePropertiesIO;

my (@dirs, $help, $go, $interpro, $status, $recursive, $verbose);
my $all;
$| = 1;
my $outdir = ".";

GetOptions ( "outdir=s" => \$outdir,
              "recursive"   => \$recursive,
             "go"          => \$go,
             "interpro=s"  => \$interpro,
             "status=s"    => \$status,
             "gp=s"        => \@dirs,
             "all"         => \$all,
             "verbose"     => \$verbose,
             "help|h"      => \$help ) or die;


help() if($help);

my $dir = ".";
my $options;
$options->{status} = "public_and_checked";
$options->{recursive} = 1; 

#Read all of the GP directories
opendir(D, $dir) or die "Could not open $dir directory for reading\n";
@dirs = sort {$a cmp $b } grep{ $_ =~ /GenProp\d{4}/}readdir(D);
closedir(D) or die;

#Final quick check;
if(scalar(@dirs)){
  $options->{dirs} = \@dirs;
}else{
  die "No genome properties to evaluate\n";
}

chdir($dir);
#Now go validate
my $gp = GenomeProperties->new;

if (! GenomePropertiesIO::stats($gp, $options, $outdir)){
  die "Can not make stats as there are errors\n";
}

#----------------------------------------------------------------------------------------


sub help {

print<<EOF;

Usage: $0 <options>

--recursive : If a genome property refers to other genome properties, then by
            : follow all referred properties.
         
--status (public_and_checked|public|checked)
            : default mode is to ignore the status file and check  everything. 
            :
            : <public> check all genome properties that have public status,
            : regardless of their checked status.
            : <checked> check all genome properties that have checked status,
            : regardless of their public status.
            : <public_and_checked>, only public and checked genome properties will be
            : checked.

--go        : Use GO API to check all GO terms used in the genome properties

--interpro <file>
            : Use the file to check all of the InterPro accessions used in
            : the genome properties.

--gp <GP>
            : Check the format of the genome property. Directory containing
            : each GP is assumed to be in the present working directory.

--all       : evaluate all of the genome properties found in the present
            : working directory

--verbose   : print warnings and status when running in recursive mode
            : with a set status. i.e. --recursive and --status set
            : in addition.

--help      : prints this help message.

EOF
exit;
}
