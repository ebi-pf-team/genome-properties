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
my $cwd = $outDir."/taxonomy/proteomes";
# For each taxon, mirror its proteome set in FASTA format.
for my $taxon (keys %$taxids) {
  my $proteome = $taxids->{$taxon}->{UPid}; 
  my $file = $taxon . '.fasta';
  my $query_taxon = "http://www.uniprot.org/uniprot/?query=proteome:$proteome&format=fasta&include=yes";
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
    die "The taxid, $taxon, has no file size\n";
  }
}  
 
#Now loop oevr and chunk the files read for I5.
for my $taxon (keys %$taxids){
  print STDERR "Chunking $taxon\n";  
  my $file = $taxon . '.fasta';
  my $chunk = 1;
  my $noSeqs = 1;
  my $totalSeqs;
  open(F, "<", $file) or die "Could not open $file for reading\n";
  open(C, ">", $file.".$chunk") or die "Could not open $file for reading\n";
  while(<F>){
    if(/^>/){
      $noSeqs++;
      $totalSeqs++;
    }
    if($noSeqs > 5000){
      close(C);
      $chunk++;
      open(C, ">", $file.".$chunk") or die "Could not open $file for reading\n";
      $noSeqs = 1; 
    }
    print C $_;
  }
  close(F);
  close(C);
  $taxids->{$taxon}->{chunk} = $chunk;
  print "The file $file contains $totalSeqs\n";
}


mkdir("$cwd/i5_analysis") if(!-d "i5_analysis");
mkdir("$cwd/i5_logs") if(!-d "i5_logs");


for my $taxon (keys %$taxids){
  print "Preparing to submit $taxon\n";
  my $chunk = $taxids->{$taxon}->{chunk};

  while($chunk){
    my $file = $taxon . '.fasta.'.$chunk;
    #bsub -q production-rh7 -n 8 -M 8000 -J i5onhps /hps/nobackup/production/interpro/sw/interproscan/current/interproscan.sh -i /hps/nobackup/production/interpro/sw/interproscan/current/test_all_appl.fasta -o interproscan_test_all_appl.tsv -f tsv
    if(!-e "$cwd/i5_analysis/$taxon.$chunk.tsv" or !-s "$cwd/i5_analysis/$taxon.$chunk.tsv"){
      if(-e "$cwd/i5_logs/$taxon.$chunk.out"){
        unlink("$cwd/i5_logs/$taxon.$chunk.out");
      }
      system( "bsub -o $cwd/i5_logs/$taxon.$chunk.out -q production-rh7 -n 8 -M 8000 -J i5onhps \"/hps/nobackup/production/interpro/sw/interproscan/current/interproscan.sh -appl tigrfam,pfam,cdd,panther,hamap,prints,pirsf,smart  -i $cwd/$file -o $cwd/i5_analysis/$taxon.$chunk.tsv -f tsv\"" );
      #warn "Missing $file\n";
    }
    $chunk--;
  }
}


#Need to write wait function here.....
my $incomplete = 1;
while($incomplete){
  my $missing = 0;
  
  print "checking that all I5 jobs have finished\n";

  for my $taxon (keys %$taxids){
    my $chunk = $taxids->{$taxon}->{chunk};
    while($chunk){
      my $file = "$taxon.$chunk.tsv";
      $missing++ if(!-e "$cwd/i5_analysis/$file");
      $chunk--;
    }
  }

  if($missing == 0){
    print "All I5 jobs complete\n";
    $incomplete = 0;
  }else{
    print "There are $missing files, will wait 10 minutes and check again.\n";
    sleep(600);
  }
}




for my $taxon (keys %$taxids){
  print "Joining files for $taxon\n";
  my $chunk = $taxids->{$taxon}->{chunk};

  my $all_i5;
  while($chunk){
    my $file = "$taxon.$chunk.tsv";
    $all_i5 .= read_file("$cwd/i5_analysis/$file");
    $chunk--;
  }
  write_file("$cwd/i5_analysis/$taxon.tsv", $all_i5);
  
  
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
