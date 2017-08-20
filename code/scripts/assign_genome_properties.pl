#!/usr/bin/env perl
#
# Re-worked version of Genome Properties
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
              'seqs=s',
              'matches=s', 
              'gpdir=s',
              'gpff=s',
              'outdir=s',
              'outfiles=s@',
              'property=s',
			        'list=s',       
			        'all',
			        'name=s',
              'debug',
              'help',
              'db',
              'eval_order=s') or die "Failed to parse options\n";;


if($options{help}){
  help();
}

my $gp = GenomeProperties->new;

$gp->set_options(\%options, 'cal');
$gp->open_outputfiles;
$gp->read_properties;
$gp->define_sequence_set;
$gp->annotate_sequences;
$gp->evaluate_properties;
$gp->write_results;
$gp->close_outputfiles;


exit;

=head1

Title:


=cut

sub help{

#TODO Improve help section
  print<<EOF;

$0 -seqs 1005058.fasta -matches 1005058.tsv -all -name 1005058.out  -eval_order evaluation_order


EOF
exit;
}

#==================================
