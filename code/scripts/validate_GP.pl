#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use GenomePropertiesIO;

my (@dirs, $help, $go, $interpro, $status, $recursive);
my $all;
$| = 1;

GetOptions ( "recursive"   => \$recursive,
             "go=s"        => \$go,
             "interpro=s"  => \$interpro,
             "status=s"    => \$status,
             "gp=s"        => \@dirs,
             "all"         => \$all,
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
  $options->{goterms} = readGOFile($go); 
}

if($interpro){
  $options->{interpro} = readInterProFile($interpro);
}

#Read all of the GP directories
if($all){
  opendir(D, ".") or die "Could not open the current working directory for reading\n";
  @dirs = sort {$a cmp $b } grep{ $_ =~ /GenProp\d{4}/}readdir(D);
  closedir(D) or die;;
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


sub readGOFile {
  my($file) = @_;
  my $goterms;
  
  open(F, '<', $file) or die "Could not open file\n";
  while(<F>){
    #GO terms look something like this GO:0070502
    if(/^(GO\:\d{7})$/){
      $goterms->{$1}++;
    }else{
      warn "Did not recognise GO term: $_";
    }
  }
  close(F) or die "Could not close filehandle\n";
  
  return($goterms);
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
            : <public> check all geneome properties that have public status,
            : regardless of their checked status.
            : <checked> check all genome properties that have checked status,
            : regardless of their public status.
            : <public_and_checked>, only public and checked genome properties will be
            : checked.

--go <file> :Use the file to check all GO terms used in the genome properties

--interpro <file>
            : Use the file to check all of the InterPro accessions used in
            : the genome properties.

--gp <GP>
            : Check the format of the genome property. Directory containing
            : each GP is assumed to be in the present working directory.

--all       : evaluate all of the genome properties found in the present
            : working directory

--help      : prints this help message.

EOF
exit;
}
