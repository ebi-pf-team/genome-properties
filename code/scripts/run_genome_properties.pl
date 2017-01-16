#! /usr/bin/perl -w

#######################################
#Shell program for genome_properties
#Flags NONE DEFINED YET
#
# Created: 18 Aug 2016 NDR
########################################

use strict;
use Getopt::Long;
use IO::File;

# Currently set to do one proteome only

# Get hist name
my $host = `hostname`;
chomp($host);

# Calculate memory requirements
my $membyte = 1000;

# Get parameters
# eventually this will be a loop reading from directory of fasta files
my @list;
my $DATA_DIR = '/nfs/production/interpro/genome_properties/data/genomes/fasta/';
if ($ARGV[0]) {
   my $taxID = $ARGV[0];
   my $file = $taxID;
   print "Proteome = $file\n";
   push (@list,$file);
}
else {
     opendir(INDIR,"$DATA_DIR");
     while (my $file=readdir(INDIR)) {
           if ($file =~ /.*.fasta$/) {
              $file =~ s/\.fasta//; 
              print "Proteome = $file\n";
              push (@list,$file);
           }
     }
     closedir(INDIR);
}


my $taxID;
my $eval_order = '/nfs/production/interpro/genome_properties/data/genome_properties_flatfiles_EBI/evaluation_order';

foreach my $taxID (@list) {
   my $fasta = $DATA_DIR.$taxID.'.fasta';
   print "taxID = $taxID\n";

   # create directory for results - do we need to check if directory exists first?
   my $RESULTS_DIR = '/nfs/production/interpro/genome_properties/data/genomes/gp_calculation/'.$taxID;
   if (-e $RESULTS_DIR) {}
   else {
     chdir('/nfs/production/interpro/genome_properties/data/genomes/gp_calculation/');
     print "Making directory $taxID\n";
     mkdir($taxID);
   }
   chdir($RESULTS_DIR);

   # submit job to farm
   print "host = $host; taxID = $taxID\n";
   my $fh = new IO::File;
   print "| bsub -R \"select[mem>$membyte] rusage[mem=$membyte]\" -M $membyte -q research-rh6 -o $taxID.err -J \"$taxID\" \n";
   $fh -> open("| bsub -R \"select[mem>$membyte] rusage[mem=$membyte]\" -M $membyte -q research-rh6 -o $taxID.err -J \"$taxID\" ") or die "$!";
   $fh -> print("/nfs/production/interpro/genome_properties/code/genome_properties_JCVI/genome_properties.pl -seqs $fasta -all -name $taxID -eval_order $eval_order\n");
   print("/nfs/production/interpro/genome_properties/code/genome_properties_JCVI/genome_properties.pl -seqs $fasta -all -name $taxID -eval_order $eval_order\n");
   $fh -> close;
   
   #die;
}






