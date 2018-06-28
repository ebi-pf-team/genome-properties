use Test::More tests => 11;
use Cwd 'abs_path';
use File::Basename;
use File::Slurp;
use File::Temp qw/ tempdir /;

use strict;
use warnings;

#Work out where the data is
my $data_dir = abs_path($0);
$data_dir    =~ s|01GenomeProperties\.t|data|;

my $tempdir = tempdir( CLEANUP =>  0 );

use_ok( 'GenomeProperties');
my $gp = GenomeProperties->new;
isa_ok($gp, "GenomeProperties");

ok($gp->set_options({ matches => $data_dir."/01_matches", 
                   all     => 1,
                   name     => "test",
                   outfiles => ["summary"],
                   outdir   => $tempdir,
                   gpdir   => $data_dir,
                   gpff    => "01_gpff" },                "cal"), "Set options");


diag("Outdir is $tempdir\n");
ok($gp->open_outputfiles, "Open output files");
is($gp->_gp_flatfile, $data_dir."/01_gpff", "set flatfile");
ok($gp->read_properties, "read_properties");
ok($gp->evaluate_properties, "Evaluate properties");
ok($gp->write_results, "Writing out results");
ok($gp->close_outputfiles, "Close file handle");

#Basic file based genome properties, now test in memory.


my $gp2 = GenomeProperties->new;
my $inline = read_file($data_dir."/01_matches");
ok($gp2->set_options({ matches => $inline, 
                   all     => 1,
                   name     => "test_inline",
                   outfiles => ["summary"],
                   outdir   => $tempdir,
                   match_source => "inline",
                   gpdir   => $data_dir,
                   gpff    => "01_gpff" },                "cal"), "Set options");


$gp2->open_outputfiles;
$gp2->read_properties;
$gp2->evaluate_properties;
$gp2->write_results;
$gp2->close_outputfiles;
my $res1 = read_file("$tempdir/SUMMARY_FILE_test");
my $res2 = read_file("$tempdir/SUMMARY_FILE_test_inline");
cmp_ok($res2, 'eq', $res1, "Equivalent results for file/inline matches");

$gp2->set_options({outfiles => ["table"], all => 1}, "cal");
$gp2->open_outputfiles;
$gp2->write_results;
$gp2->close_outputfiles;

my @inline = read_file($data_dir."/01_matches");
$inline = join("", @inline[0..1]);
my $gp3 = GenomeProperties->new;
$gp3->set_options({matches => $inline,
                   name => "test_partial", 
                   outfiles => ["table", "comp_table"],
                   outdir   => $tempdir,
                    match_source => "inline",
                   gpdir   => $data_dir,
                   gpff    => "01_gpff",
                   all => 1}, "cal");
$gp3->open_outputfiles;
$gp3->read_properties;
$gp3->evaluate_properties;
$gp3->write_results;
$gp3->close_outputfiles;





