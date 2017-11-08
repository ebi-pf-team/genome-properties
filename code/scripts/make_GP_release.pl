#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Slurp;

use GenomePropertiesIO;

my (@dirs, $help, $go, $interpro, $status, $recursive, $verbose);
my $all;
$| = 1;

GetOptions ( "recursive"   => \$recursive,
             "go"          => \$go,
             "interpro=s"  => \$interpro,
             "status=s"    => \$status,
             "gp=s"        => \@dirs,
             "all"         => \$all,
             "verbose"     => \$verbose,
             "help|h"      => \$help ) or die;


help() if($help);

my $scratch = '/tmp/scratch';
my $releaseDir = '/tmp/';
my $version    = '0.1';

my $options;

$options->{status} = "public_and_checked";
$options->{recursive} = 1;
$options->{checkgoterms} = 1; 
$options->{interpro} = readInterProFile($interpro);
$options->{verbose} = 1;

#In theory, we want to checkout HEAD from git.
chdir($scratch) or die "Could not chdir $scratch:[$!]\n";
system("git clone https://github.com/rdfinn/genome-properties.git");

#Now validate the data.
my $datadir = "$scratch/genome-properties/data";
my $docsdir = "$scratch/genome-properties/docs";
#Read all of the GP directories
opendir(D, $datadir) or die "Could not open $datadir directory for reading\n";
@dirs = sort {$a cmp $b } grep{ $_ =~ /GenProp\d{4}/}readdir(D);
closedir(D) or die;

#Final quick check;
if(scalar(@dirs)){
  $options->{dirs} = \@dirs;
}else{
  die "No genome properties to evaluate\n";
}

chdir($datadir);
#Now go validate
my $gp = GenomeProperties->new;
if (! GenomePropertiesIO::validateGP($gp, $options)){
  die "Can not make release as there are errors\n";
}

#Now make the release directory
if(! -d $releaseDir."/".$version ){
  mkdir( $releaseDir."/".$version ) or die "Could not make the release directory";
}

#Concatenate all DESC files that are listed 
#$gp object, place in the flatfile directory

open(R, ">", $releaseDir."/".$version."/PropertyDefinitions") or 
  die "Could not open ".$releaseDir."/".$version."/PropertyDefinitions, [$!]";

foreach my $gp ( sort keys { %{ $gp->get_defs } } ){
  my @f = read_file( $datadir."/".$gp."/DESC");
  foreach my $line (@f){
    next if(substr($line,0,2) eq "**");
    print R $line;
  }
}
close(R);

#Version file
open(V, ">", "$releaseDir/$version/version") or die "Could not open $releaseDir/$version/version";
print V "Genome Properties version: $version\nDependency on InterProScan version: XX\n";
close(V);

#Git Tag...
chdir("$scratch/genome-properties");
system("git tag -f -a $version -m \"Genome Properties release $version\"");

#Release notes?
#system("sphinx-build -b latex  $docsdir $scratch/latex");
#chdir("$scratch/latex");
#system("pdflatex GenomeProperties  > GenomeProperties.pdf");
#system("cp GenomeProperties.pdf $releaseDir/$version/."); 
#open GenomeProperties.pdf 


#Git push...
#system("git push");

#Copy to an ftp site....



#----------------------------------------------------------------------------------------
#Move this into GPIO, fix in validate GP script....

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



#----------------------------------------------------------------------------------------


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
