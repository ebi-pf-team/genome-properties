#!/usr/bin/env perl 
#
# Script that downloads a set of complete genomes from UniProt to allow us
# to calculate InterProScan matches against and the infer Genome Properties.
#

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Date;
use Getopt::Long;
use File::Slurp;

my ($taxList, $outDir, $help);

GetOptions( "out=s"     => \$outDir,
            "taxlist=s" => \$taxList,
            "help"      => \$help    ) or die "Unknown option\n";

#This means Complete proteome
my $keyword =  'keyword:181';

if(!$outDir){
  die "Please specify an output directory, see --help for more details\n";
}
if(!$taxList){
  die "Please specify a list of genomes, see --help for more details\n";
}
if($help){
  help()
}

#Set up the UA
my $agent = LWP::UserAgent->new;
$agent->env_proxy;

#Read in the file of proteomes that we want to fetch
my @taxlist = read_file($taxList, chomp => 1);
my $taxids;
foreach my $l (@taxlist){
  my($species, $tid, $up) = split(/,/, $l);
  $taxids->{$tid}->{name}  = $species;
  $taxids->{$tid}->{found} = 0;
  $taxids->{$tid}->{UPid}  = $up;
}


if(!-e $outDir."/taxonomy"){
  mkdir($outDir."/taxonomy") or die "Could not make directory $outDir/taxonomy"; 
}
if(!-e $outDir."/taxonomy/proteomes"){
  mkdir($outDir."/taxonomy/proteomes") or die "Could not make directory $outDir/taxonomy/proteomes";
}
chdir($outDir."/taxonomy/proteomes") or die "Could not change to directory $outDir/taxonomy/proteomes";

# For each taxon, mirror its proteome set in FASTA format.
for my $taxon (keys %$taxids) {
   
  my $file = $taxon . '.fasta';
  my $query_taxon = "http://www.uniprot.org/uniprot/?query=organism:$taxon+$keyword&format=fasta&include=yes";
  my $response_taxon = $agent->mirror($query_taxon, $file);

  if ($response_taxon->is_success) {
    my $results = $response_taxon->header('X-Total-Results');
    my $release = $response_taxon->header('X-UniProt-Release');
    my $date = sprintf("%4d-%02d-%02d", HTTP::Date::parse_date($response_taxon->header('Last-Modified')));
    print "File $file: downloaded $results entries of UniProt release $release ($date)\n";
  }elsif ($response_taxon->code == HTTP::Status::RC_NOT_MODIFIED) {
    print "File $file: up-to-date\n";
  }else {
    die 'Failed, got ' . $response_taxon->status_line .
      ' for ' . $response_taxon->request->uri . "\n";
  }

  #Now check that the file has a size.
  if(!-s $file) {
    warn "The taxid, $taxon, has no file size\n";
  }else{
    my $chunk = 1;
    my $noSeqs;
    open(F, "<", $file) or die "Could not open $file for reading\n";
    while(<F>){
      $noSeqs++ if(/^>/)
    }
    close(F);
    print "The proteome $taxon contained $noSeqs sequences\n";
  }


}


sub help {

print<<EOF
$0
usage:

out     : Output directory
taxlist : File containing the list of taxids that you want to retrieve
help    : Prints this help message

EOF

}
