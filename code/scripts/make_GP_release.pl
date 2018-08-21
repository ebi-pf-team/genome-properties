#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Slurp;
use File::Copy;
use Cwd qw(abs_path getcwd);
use GenomePropertiesIO;

my (@dirs, $help, $interpro, $i5version, $gitBranch, $scratch, $releaseDir );
my $all;
$| = 1;

my $version;

GetOptions ( "scratch=s"    => \$scratch,
             "releasedir=s" => \$releaseDir, 
             "interpro=s"   => \$interpro,
             "version=s"    => \$version,
             "i5version=s"  => \$i5version,
             "git-branch=s" => \$gitBranch,
             "help|h"       => \$help ) or die;


help() if($help);

if(!$scratch){
  warn "No scratch directory supplied\n";
  help();
}

if(!-d $scratch){
  die "The scratch directory, $scratch does not exist\n";
}
$scratch = abs_path($scratch);

if(!$releaseDir){
  warn "No release directory supplied\n";
  help();
}

if(!-d $releaseDir){
  die "The release contianer directory, $releaseDir does not exist\n";
}
$releaseDir = abs_path($releaseDir);


if(!$i5version){
  warn "Interproscan version not definedi\n";
  help();
}

if(!$version){
  warn "No version defined\n";
  help();
}

if(! $gitBranch){
  warn "Please indicate the git branch to checkout after cloning.\n";
  help();

}

if(!$interpro){
  warn "No InterPro file provided\n";
  help();
}
if(!-s $interpro){
  die "The interpro file $interpro does not exist or has no size\n";
}


my $options;

$options->{status} = "public_and_checked";
$options->{recursive} = 1;
$options->{checkgoterms} = 1; 
$options->{interpro} = readInterProFile($interpro);
$options->{verbose} = 1;
$options->{startdir} = getcwd();

#TODO: Check the the I5 version and the central install versions are appropriate.



#We want to checkout HEAD from git.
chdir($scratch) or die "Could not chdir $scratch:[$!]\n";
system("git clone https://github.com/ebi-pf-team/genome-properties.git");
chdir("genome-properties") or die "Could not change into genome properties directory\n";
system("git checkout $gitBranch") and die "Failed to checkout $gitBranch from github\n";
chdir($scratch) or die "Could not change back to the scratch working directory are git checkout\n";

#Now validate the data.
my $datadir = "$scratch/genome-properties/data";
my $docsdir = "$scratch/genome-properties/docs";
my $flatdir = "$scratch/genome-properties/flatfiles";
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

#Now check the hierarchy
GenomePropertiesIO::checkHierarchy($gp, $options);

#Now make the release directory
if(! -d $releaseDir."/".$version ){
  mkdir( $releaseDir."/".$version ) or die "Could not make the release directory";
}

#Concatenate all DESC files that are listed 
#$gp object, place in the flatfile directory

open(R, ">", $releaseDir."/".$version."/genomeProperties.txt") or 
  die "Could not open ".$releaseDir."/".$version."/genomeProperties.txt, [$!]";

foreach my $gp ( sort keys { %{ $gp->get_defs } } ){
  my @f = read_file( $datadir."/".$gp."/DESC");
  foreach my $line (@f){
    next if(substr($line,0,2) eq "**");
    print R $line;
  }
}
close(R);

# Write out the JSON files
# 1. GP hierarchy files
# 2. Taxonomy tree for the species tree


#Now generate the hierarchy JSON file
my $json = GenomePropertiesIO::JSONHierarchy($gp);
open(J, ">", $releaseDir."/".$version."/hierarchy.json") or 
  die "Could not open ".$releaseDir."/".$version."/hierarchy, [$!]";
print J $json;
close(J);

#Within the GP directiry, there should be a species list.
#Get this an make an ncbi taxonomy tree, based on this subset of species

if(! -e "$releaseDir/taxonomy/tree.json"){ 
  system("ncbi_taxonomy.pl -out $releaseDir -taxList $flatdir/proteome_list.csv") and die "Failed to make taxonomy tree\n";
}
#Now download the the proteomes in the taxList and assign genome properties from the new assembled flatfile

system("get_proteome.pl -out $releaseDir -taxlist $flatdir/proteome_list.csv -gpdir $releaseDir/$version") and die "Failed to run get_proteome script\n";;

#Version file
open(V, ">", "$releaseDir/$version/version.txt") or die "Could not open $releaseDir/$version/version.txt";
print V "Genome Properties version: $version\nDependency on InterProScan version: $i5version\n";
close(V);

#Now make the stats
chdir("$scratch/genome-properties/data") or die "Chould not change directory to $scratch/genome-properties/data";
system("make_GP_stats.pl -outdir $scratch/genome-properties/docs/_stats"); 
#Want to commit these in....

#TODO: Add

#TODO:Need to generate a white list




#Now start organising things into the appropriate directories
# TODO:Agree name and fix.
copy("$releaseDir/taxonomy/tree.json", "$releaseDir/$version/taxonomy.json");
copy("$releaseDir/taxonomy/tree.json", "$flatdir/taxonomy.json");


my $gpaDir = "$releaseDir/taxonomy/proteomes/gp_assingments";
opendir MYDIR, $gpaDir  or die "Could not opendir $gpaDir: $!\n";
my @allfiles = grep { $_ ne '.' and $_ ne '..' } readdir MYDIR ;
closedir(MYDIR);

my $gpaRelDir = "$releaseDir/$version/gp_assignments";
if(!-d $gpaRelDir){
  mkdir($gpaRelDir) or die "Could not make diretory $gpaRelDir:[$!]\n";
}

foreach my $f (@allfiles){
  copy("$gpaDir/$f", "$gpaRelDir/$f");
  copy("$gpaDir/$f", "$flatdir/gp_assignments/$f");  
}

#Copy all files across and commit in.
copy("$releaseDir/$version/version.txt", "$flatdir/version.txt");
copy("$releaseDir/$version/hierarchy.json", "$flatdir/hierarchy.json"); 

#Git Tag...
chdir("$scratch/genome-properties");
system("git commit -a -m \"Updated release file for release $version\"");
#system("git tag -f -a $version -m \"Genome Properties release $version\"");

#Git push...
system("git push");

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



--scratch <dir>
              : A directory where files will be temporarily stored during making the
              : the release

--releasedir <dir>
              : directory for storing all of the files that we want to keep, but
              : no necessarily put under version control. Some of the files
              : generated there will be put under version control.

--version  <string>    
              : version label to add to Genome Properties release.

--interpro <file>
            : Use the file to check all of the InterPro accessions used in
            : the genome properties.

--i5version <string>
            : String indicating the version of InterProScan that this release works with.

--git-branch <string>
            : Name of the git branch that the release should be built from.


--help      : prints this help message.


EOF
exit;
}
