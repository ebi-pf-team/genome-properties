#!/usr/bin/env perl
#
# Read Genome Properties from flat and write out as  DESC files
#

use strict;
use warnings;
$|=1;
use FileHandle;
use Getopt::Long;
use Data::Printer;
use List::Util qw[min max];
use GenomeProperties;
use GenomeProperties::Definition;
use GenomeProperties::Step;
use GenomeProperties::StepEvidence;


my(%options);
GetOptions ( \%options, 
              'gpdir=s',
              'outdir=s',
              'property=s',
			        'list=s',       
			        'all',
			        'name=s',
              'debug',
              'help',
              'db',
              'db_out') or die "Failed to parse options\n";;


if($options{help}){
  help();
}

my $gp = GenomeProperties->new;

$gp->set_options(\%options, 'flat');
$gp->read_properties;

$gp->toDESCHack;

exit;

=head1

Title:


=cut

sub help{

#TODO Improve help section
  print<<EOF;
  
  Holy crap!

<$0> -seqs /nfs/production/interpro/genome_properties/data/genomes/fasta/1005058.fasta -all -name 1005058  -eval_order /nfs/production/interpro/genome_properties/code/genome_properties_flatfiles/evaluation_order

EOF
exit;
}

#==================================
