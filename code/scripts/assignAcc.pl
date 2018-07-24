#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use File::Copy;
use File::Slurp;
use DDP;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );

my ($repoURL, $help, $inDir, $outDir);

GetOptions( "r|repo=s" => \$repoURL, 
            "in=s"     => \$inDir,
            "out=s"    => \$outDir,
            "h|help" => \$help) or die "Invalid option\n";

help() if($help);
die if(!$repoURL);

if($repoURL !~ /\/data$/){
  die "Please check your URL, expected the genome properties data directory\n";
}

my $content;
my $response = $ua->get($repoURL);
if ( $response->is_success ) {
  $content = $response->decoded_content;
} else {
  die $response->status_line;
}

my @gps = $content =~ /GenProp(\d{4})/g;
my @nextAcc;

foreach my $acc (@gps){
  $nextAcc[$acc] = 1;
}


my $gpAcc = 0;

for (my $i=1106; $i<=scalar(@nextAcc); $i++){
  if(!$nextAcc[$i]){
    $gpAcc = $i;
    last;
  }
}

opendir(IN, $inDir) or die "Could not open the input directory, $inDir\n";
my @dirs = grep { $_ ne '.' && $_ ne '..' }readdir(IN);
close(IN);

foreach my $gp (@dirs){
  next unless (-d "$inDir/$gp");
  my $acc = "GenProp".sprintf("%04d", $gpAcc);
  $gpAcc++;
  mkdir("$outDir/$acc") or die "Could mot mkdir $outDir/$acc\n";;
FILE:
  foreach my $f (qw(DESC FASTA status)){
    next FILE unless(-e "$inDir/$gp/$f");
    copy("$inDir/$gp/$f","$outDir/$acc/$f") or die "Copy failed: $!";
  }
  if(-e "$outDir/$acc/DESC"){
    my @desc = read_file("$outDir/$acc/DESC");
    shift(@desc);
    unshift(@desc, "AC  $acc\n");
    write_file("$outDir/$acc/DESC", @desc);
  }
}

sub help{

  print "usage: $0 -repo https://github.com/ebi-pf-team/genome-properties/tree/rel2.0/data\n";
  exit;

}
