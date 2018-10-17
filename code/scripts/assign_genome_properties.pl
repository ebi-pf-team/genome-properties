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
              'match_source=s',
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
              'eval_order=s') or die "Failed to parse options\n";;


if($options{help}){
  help();
}

my $gp = GenomeProperties->new;

$gp->set_options(\%options, 'cal');
$gp->open_outputfiles;

#Read in the GP definitions file.
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

  print<<EOF;

Options:

== Sequence set ==

One or both of these two options:
matches <filename|TSV content> : TSV file of InterProScan5 output.
match_source <file|inline> : file or inline. Default is to assume file.
seq <filename>           : FASTA file of sequences that need to be analysed.


== Calculation options ==

One of the the following three:
all                      : Calculate against all Genome Properties 
property <accession>     : Calculate against 
list     <filename>      : Filename containing a list of Genome Properties that need 
                         : to be evaluatated.

== Genome Properties files == 
Both of these are required: 
gpdir <directory name>   : Genome Properties release directory
gpff  <filename>         : Name of the flatfile  

Optional:
eval_order <filename>    : File containing an optimal evaluation order.

== Output options ==

name <name>              : Output file tag name (required). This will be prefixed 
                           depending on the outputs requested.
outdir <directory name>  : Name of the output directory (optional, default pwd).
outfiles <format>        : Format can be one of the following [summary|long|table|match|web_json]
                         : To get multiple output files use option multiple times


-- Other --
help                     : Prints this help message
debug                    : Turn on verbose debugging


Example: 
$0 -matches /Users/rdf/Projects/InterPro/GenomeProperties/EcoliExample/83333.fasta.tsv  -all -name 83333.test -gpdir /tmp/release/testv0.1 -gpff genomeProperties.txt -outfiles summary


EOF
exit;
}
