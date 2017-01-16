#! /usr/bin/perl -w

#######################################
#Summary program for genome_properties
#Flags NONE DEFINED YET
#
# Created: 22 Aug 2016 NDR
########################################

use strict;
use Getopt::Long;
use IO::File;

my %species;

# Read directory /nfs/production/interpro/genome_properties/data/genomes/gp_calculation
my %list;
my $DATA_DIR = '/nfs/production/interpro/genome_properties/data/genomes/gp_calculation/';
opendir(INDIR,"$DATA_DIR");
while (my $file=readdir(INDIR)) {
      $file =~ s/\.fasta//; 
      print "TaxID = $file\n";
      $list{$file}++;
}
closedir(INDIR);

# Read in taxonomy_list and translate TaxID to organism name
my $tax_list = '/nfs/production/interpro/genome_properties/data/genomes/fasta/taxonomy_list';
open(IN,$tax_list)  || die "Unable to open $tax_list\n";
my $thisline = <IN>;  # throw away headers
while ($thisline = <IN>) {
      chomp($thisline);
      my (@temp) = split(/\t/,$thisline);
      if (($temp[0] && $list{$temp[0]})) {
         $species{$temp[0]} = $temp[2];
         print "species = $species{$temp[0]}, taxID = $temp[0]\n";
      }
}

# Now read in each summary results file in turn and generate results matrix
my @genome_property_ID;
my @genome_property_name;
my %genome_property_presence;
my $count = 0;
my $gp_count = 0;
foreach my $taxID (keys %species) {
        my $filename = $DATA_DIR.$taxID.'/SUMMARY_FILE_'.$taxID;
        open(IN,$filename) || die "Unable to open results file $filename\n";
        $count++;
        while (my $thisline = <IN>) {
              chomp($thisline);
              my (@temp) = split(/\t/,$thisline);
              if ($count == 1) {
                 $gp_count++;
                 $genome_property_ID[$gp_count] = $temp[0];
                 $genome_property_name[$gp_count] = $temp[1];
                 print "genome property ID = $genome_property_ID[$gp_count], genome property name = $genome_property_name[$gp_count]\n";
              }
              my $key = $temp[0].'_'.$taxID;
              #print "key = $key, $temp[0]; $temp[1]; $temp[2]\n";
              $genome_property_presence{$key} = $temp[2];
        }
        close(IN);
}

# Now print out results as a comma-delimited file
my $filename = $DATA_DIR.'summary_results.txt';  
print "Writing to $filename\n";
open(OUT,">$filename") || die "Unable to write to $filename\n";
print OUT "\t\t";
foreach my $taxID (keys %species) {
        print OUT "$taxID\t";
#        print "$taxID,";
}
print OUT "\n";
#print "\n";
print OUT "\t\t";
foreach my $taxID (keys %species) {
        #print "$species{$taxID},";
        print OUT "$species{$taxID}\t";
}
print OUT "\n";
for (my $j = 1; $j <= $gp_count; $j++) {
    print OUT "$genome_property_ID[$j]\t$genome_property_name[$j]\t";
    print "j = $j, genome property ID = $genome_property_ID[$j], genome property name = $genome_property_name[$j]\n";
    foreach my $taxID (keys %species) {
            my $key = $genome_property_ID[$j].'_'.$taxID;
            my $text = $genome_property_presence{$key};
            print 
            print OUT "$text\t";
    }
    print OUT "\n";
}        
close(OUT);
