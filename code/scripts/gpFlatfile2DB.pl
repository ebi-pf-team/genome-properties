#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Slurp;
use File::Copy;
use Cwd qw(abs_path getcwd);
use GenomePropertiesIO;
use GenomeProperties;
use GenomePropertiesDB;
use DDP;

my(%options);
GetOptions ( \%options, 
              'gpdir=s',
              'outdir=s',
              'gpff=s',
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

my $dbi_dsn = "dbi:mysql:database=gp_new;host=127.0.0.1;";
my $user = 'root';
my $pass = undef;
my %dbi_params;
my $schema = GenomePropertiesDB->connect($dbi_dsn, $user, $pass, \%dbi_params);

GenomePropertiesIO::gp2db($gp, $schema);


#----------------------------------------------------------------------------------------


sub help {

print<<EOF;

Usage: $0 <options>

EOF
exit;
}
