#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use GenomePropertiesIO;

my (@dirs, $help, $go, $interpro, $status, $recursive, $verbose, $connect);
my $all;
$| = 1;

GetOptions ( "recursive"   => \$recursive,
             "go"          => \$go,
             "interpro=s"  => \$interpro,
             "status=s"    => \$status,
             "gp=s"        => \@dirs,
             "all"         => \$all,
             "connect"     => \$connect,
             "verbose"     => \$verbose,
             "help|h"      => \$help ) or die;


help() if($help);


my $options;

#Determine with things we need to look at.
if($status){
  if($status !~ /(public_and_checked|checked|public)/){
    die "Unknown status $status, see --help for more information\n";
  }
  $options->{status} = $status;
}

if(defined($recursive) and $recursive == 1){
  $options->{recursive} = 1;
}

if($go){
  $options->{checkgoterms} = 1; 
}

if($interpro){
  $options->{interpro} = readInterProFile($interpro);
}

if($verbose){
  $options->{verbose} = 1;
}

if($connect and !$all){
  die "Only check connectivity where using all, this should be on all nodes\n";
}


#Read all of the GP directories
if($all){
  opendir(D, ".") or die "Could not open the current working directory for reading\n";
  @dirs = sort {$a cmp $b } grep{ $_ =~ /GenProp\d{4}/}readdir(D);
  closedir(D) or die;
}

#Final quick check;
if(scalar(@dirs)){
  $options->{dirs} = \@dirs;
}else{
  die "No genome properties to evaluate\n";
}

#Now go validate
my $gp = GenomeProperties->new;
GenomePropertiesIO::validateGP($gp, $options);
#GenomePropertiesIO::checkHierarchy($gp, $options) if($all); 
if($connect){
  $gp->checkConnectivity;
}

sub readInterProFile {
  my ($file) = @_;
  my $interProData;

  open(F, '<', $file) or die "Could not open file, $file:[$!]\n";
  while(<F>){
    if(/^ENTRY_AC/){
      ;#skip the line
    }elsif(/^IPR/){
      chomp;
      my ($ipr, $name, $signature, $ec) = split(/\t/);
      $interProData->{$ipr}->{name} = $name;
      $interProData->{$ipr}->{signatures}->{$signature}->{$ec}++;
    }
  }
  close(F) or die "Could not close filehandle\n";
  
  return($interProData);
}


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

--connect   : This should only be used in combination with the --all
            : flag and assumes you are working on the whole set of
            : Genome Properties.  It takes the root category and 
            : loops over all steps to make sure all genome properties
            : are connected.

--help      : prints this help message.

EOF
exit;
}
