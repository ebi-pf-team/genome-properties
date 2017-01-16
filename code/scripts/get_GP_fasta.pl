#! /usr/bin/perl -w

#######################################
#Shell program for genome_properties
#Flags NONE DEFINED YET
#
# Created: 23 Aug 2016 NDR
########################################

use strict;
use Getopt::Long;
use LWP::UserAgent;
use IO::File;

my $keyword =  'keyword:181';

my $agent = LWP::UserAgent->new;
$agent->env_proxy;

# Read in ordered list of proteomes
my $infile = '/nfs/production/interpro/genome_properties/test/proteomes.txt';
my $spec_count = 0;
my @orgnam;
my @taxID;
my @GPStep;
open(IN,$infile) || die "Unable to open $infile\n";
while (my $thisline = <IN>) {
      chomp($thisline);
      my ($species,$taxID) = split(/\t/,$thisline);
      # How to store these?  Not as hash because order will be lost!
      $spec_count++;
      $orgnam[$spec_count] = $species;
      $taxID[$spec_count] = $taxID;
      #print "$spec_count: $taxID[$spec_count], $orgnam[$spec_count]\n";
}
print "All genome names read in\n";

# Read in list of genome properties and steps
$infile = '/nfs/production/interpro/genome_properties/test/gp_steps_hmm.txt';
my $counter = 0;
open(IN,$infile) || die "Unable to open $infile\n";
while (my $thisline = <IN>) {
      chomp($thisline);
      my ($genpropID,$step_num) = split(/\t/,$thisline);
      #print "genome property id = $genpropID, step number = *$step_num*\n";
      $counter++;
      $GPStep[$counter] = $genpropID."#".$step_num;
      #print "$counter: $GPStep[$counter]\n";
}
print "All Genome Property steps read in\n";

# For each step in genome property, retrieve one sequence from a proteome in FastA format and add to file
my $old_genpropID = 'GenProp0000';
my $report_file = '/nfs/production/interpro/genome_properties/test/report_gp_steps.txt';
open(OUT2,">$report_file") || die "Unable to open $report_file.\n";
for (my $i = 0; $i <= $counter; $i++) {
    my $temp = $GPStep[$i];
    unless ($temp) {next}
    my ($genpropID,$step_num) = split(/\#/,$temp);
    my $got_step = 0;
    if ($genpropID ne $old_genpropID) {
       if ($i > 0) {close(OUT)}
       #if ($i > 1) {die}
       my $outfile = '/nfs/production/interpro/genome_properties/test/'.$genpropID.'.fasta';
       open(OUT,">$outfile") || die "Can't write to $outfile\n";
       print "outfile = $outfile\n";
       $old_genpropID = $genpropID;
    }
    for (my $j = 1; $j <= $spec_count; $j++) {
        my $taxID = $taxID[$j];
        $infile = '/nfs/production/interpro/genome_properties/data/genomes/gp_calculation/'.$taxID.'/TABLE_'.$taxID;
        print "infile = $infile\n";
        open(IN,$infile) || {next};
        my $thisline = <IN>; # throw away header
        while ($thisline = <IN>) {
              chomp($thisline);
              if ($thisline =~ /NO_HITS/) {next}
              if ($thisline =~ /N\/A/) {next}
              my (@temp) = split(/\t/,$thisline);
              if (($temp[0] =~ /^$genpropID/) && ($temp[3] eq $step_num) && ($got_step == 0)) {
                 my ($uniprot_acc) = $temp[9] =~ /\|(.*)\|/;
                 unless ($uniprot_acc =~ /[A-Z0-9]+/) {next}  # skip any UniProt accession with a non-word character or underscore
                 print "GenomePropertyID = $genpropID ($temp[0]); step num = $step_num; UniProt = $uniprot_acc ($temp[9])\n";
                 my $url = 'http://www.uniprot.org/uniprot/'.$uniprot_acc.'.fasta';
                 unless ($uniprot_acc) {die "URL = $url; $temp[9]\n"}
                 my $response_sum = $agent->get($url);
                 if ($response_sum->is_success) {
                    print OUT $response_sum->content."\n";
                    $got_step = 1;
                 }
              }
        }
        if ($got_step == 1) {$j = $spec_count}
        close(IN);
    }
    if ($got_step == 0) {
       print OUT2 "$GPStep[$i] not found.\n";
    }
}
close(OUT);
close(OUT2);

