#!/usr/bin/env perl

##### This code is designed to build up the NCBI taxonomy trees
# At the moment is uses the taxonomy.dat file which is downloaded from EBI

use strict;
use warnings;

use JSON;
use LWP::Simple;
use Getopt::Long;
use Archive::Tar;
use File::Slurp;
use Log::Log4perl qw(:easy);
use Cwd 'abs_path';

Log::Log4perl->easy_init($DEBUG);

my ($taxList, $outDir, $help, $force);
GetOptions( "out=s"     => \$outDir,
            "force=i"   => \$force,
            "taxlist=s" => \$taxList,
            "help"      => \$help    ) or die "Unknown option\n";

if(! defined($outDir)){
  warn "Need to define an output directory\n";
  help();
}

if(!-d $outDir){
  die "The output directory, $outDir does not exist\n";
}
$outDir = abs_path($outDir);


if(!defined($taxList)){
  warn "The list of proteomes was not defined\n"; 
  help();
}
if(! -s $taxList){
  die "The list of proteomes, $taxList, has no size or does not exist\n"; 
}


#-------------------------------------------------------------------------------
#- main ------------------------------------------------------------------------
#-------------------------------------------------------------------------------

my $logger = Log::Log4perl->get_logger();


$logger->info('Processing the proteome list');
my @taxlist = read_file($taxList, chomp => 1);
my $taxids;
foreach my $l (@taxlist){
  my($up, $tid, $species) = split(/,/, $l);
  $taxids->{$tid}->{name}  = $species;
  $taxids->{$tid}->{found} = 0;
  $taxids->{$tid}->{UPid}  = $up;
}


#-------------------------------------------------------------------------------
# Get the taxonomy data from NCBI
$logger->info('Getting ncbi data');

my $outDirTax = $outDir.'/taxonomy';

#Store the taxonomy file for future reference.
unless ( -d $outDirTax ) {
    mkdir( $outDirTax )
        or die "Could not make the directory $outDirTax because: [$!]\n";
}

foreach my $f (qw(taxdump.tar.gz)){
  my $thisFile = $outDirTax."/".$f;
  if($force){
    if(-e $thisFile){
      unlink($thisFile) or die "Failed to remove $thisFile: [$!]\n";  
    }
  }


  if(!-e $thisFile){
    my $rc = getstore(
      'ftp://ftp.ncbi.nih.gov/pub/taxonomy/'.$f, $thisFile); 
    die 'Failed to get the file ncbi taxdump' unless ( is_success($rc) );
  }
}

$logger->info('Extracting ncbi data');
my $tar = Archive::Tar->new;
$tar->read( $outDirTax. '/taxdump.tar.gz' );
if(!-e $outDirTax.'/nodes.dmp' or $force){
  $tar->extract_file( 'nodes.dmp', $outDirTax .'/nodes.dmp' );
}
if(!-e $outDirTax.'/names.dmp' or $force){
  $tar->extract_file( 'names.dmp', $outDirTax.'/names.dmp' );
}
#-------------------------------------------------------------------------------
# Build up all the ncbi nodes. Read into a hash array
$logger->info('Parsing ncbi data (names.dmp)');

#------------------------------------------------------------------------------
#This is a bit of a hack, but we want to keep these levels so we can hang
#all sequences off this

#Move to config
my %promote;
foreach
  my $l ( "Viroids", "Viruses", "unclassified sequences", "other sequences" )
{
  $promote{$l}++;
}

my %promoteTaxIds;

#------------------------------------------------------------------------------
# Extract just the scientific names (for the time being, it may be useful to
# have synonyms and lay terms ).
#
my %names;
my %minNames;
open( _NAMES, $outDirTax. '/names.dmp' )
  or die "Could not open $outDirTax/names.dmp: [$!]\n";
while (<_NAMES>) {
  next unless (/scientific name/);
  @_ = split( /\|/, $_ );
  my ($taxid) = $_[0] =~ /(\d+)/;
  my ($name)  = $_[1] =~ /\s+(.*)\s+/;
  $names{$taxid} = $name;
  $promoteTaxIds{$taxid}++ if ( $promote{$name} );
}
close(_NAMES);

#------------------------------------------------------------------------------
#Now parse the nodes file
#
open( _NODES,  $outDirTax.'/nodes.dmp'  )
  or $logger->logdie("Could not open nodes.dmp: [$!]");

my $nodes = [];    #This will be out store for all the nodes in the tree
while (<_NODES>) {
  @_ = split( /\|/, $_ );
  my ($taxid)  = $_[0] =~ /(\d+)/;
  my ($parent) = $_[1] =~ /(\d+)/;
  my ($rank)   = $_[2] =~ /\s+(.*)\s+/;
  #Shunt those special ids to be superkingdoms.
  $rank = 'superkingdom' if ( $promoteTaxIds{$taxid} );
    
  unless(defined($names{$taxid})){
     #warn $taxid. " has no name\n"; 
     $names{$taxid} = '_unnamed';
  }
  $nodes->[$taxid] = {
                       taxid  => $taxid,
                       parent => $parent,
                       rank   => $rank,
                       name   => $names{$taxid} };
  
}
close(_NODES);

#------------------------------------------------------------------------------
#Now build the fuill tree as we get it from NCBI
#
$logger->info('Building full taxonomic tree');
my $treeJson = $outDirTax."/tree.json";

if($force or !-e $treeJson){
  my $tree = {};

#------------------------------------------------------------------------------
# Cut out the levels that are excessive by reassigning parentage
#
$logger->info('Removing excessive nodes');
  my %ranks = ( superkingdom => 1,
                kingdom      => 1,
                phylum       => 1,
                class        => 1,
                 order        => 1,
              family       => 1,
              genus        => 1,
              species      => 1 );

  buildTree( $tree, $nodes, $taxids, \%ranks );

  my $error;
  foreach my $tid (keys %{$taxids}){
    if(!$taxids->{$tid}->{found}){
      $error.= $taxids->{$tid}->{name}." with the taxid $tid has not been found in the NCBI tree\n";
    }
  }

  if($error){
    die $error;
  }


  $logger->info('Traversing tree');
  my $count = 0;
  traverseTree( $tree, $nodes, $count );

  #------------------------------------------------------------------------------
  # Print tree out/store it in the database.
  #


  my $taxString = '';
  my $taxJson = { parent   => 0,
                  taxid    => 0,
                  name     => "root",
                  rank     => "root",
                  lineage  => "",
                  children => []};
  traverseTreeForPrint( $tree, $nodes, $taxString, $taxJson->{children});
  #p($tree);
  foreach my $child ( @{ $taxJson->{children}} ){
    $taxJson->{number_of_leaves} += $child->{number_of_leaves};
  }
  
  write_file( $treeJson, to_json($taxJson, { ascii => 1, pretty => 1 } ));

}


exit;

#------------------------------------------------------------------------------
# subroutines ----------------------------------------------------------------- 
#------------------------------------------------------------------------------

sub traverseTree {
  my ( $hash, $nodes, $count ) = @_;
  foreach my $k ( keys %{$hash} ) {
    $nodes->[$k]->{lft} = $count++;
    $count = traverseTree( $hash->{$k}, $nodes, $count );
    $nodes->[$k]->{rgt} = $count++;
  }
  return $count;
}

sub traverseTreeForPrint {
  my ( $hash, $nodes, $taxString, $taxJson ) = @_;
  foreach my $k ( keys %{$hash} ) {
    my $thisTaxString = $taxString;
    $thisTaxString .= $nodes->[$k]->{name} . ';';
    my $jNode = { parent   => $nodes->[$k]->{parent},
                  taxid    => $nodes->[$k]->{taxid},
                  name     => $nodes->[$k]->{name},
                  lft      => $nodes->[$k]->{lft},
                  rgt      => $nodes->[$k]->{rgt},
                  rank     => $nodes->[$k]->{rank},
                  lineage  => $thisTaxString,
                  children => []};

    $jNode->{UPid} = $nodes->[$k]->{UPid} if($nodes->[$k]->{UPid});

    push(@{$taxJson}, $jNode);
    traverseTreeForPrint( $hash->{$k}, $nodes, $thisTaxString, $jNode->{children} );
    if(scalar @{ $jNode->{children}} == 0){
      #This is a leaf node of the tree.
      $jNode->{number_of_leaves} = 1;
    }else{
      foreach my $child (@{ $jNode->{children}}){
        $jNode->{number_of_leaves} += $child->{number_of_leaves};
      }
    }
  }
}

sub traverseTreeAndPrint {
  my ( $hash, $nodes, $taxString ) = @_;
  foreach my $k ( keys %{$hash} ) {
    my $thisTaxString = $taxString;
    $thisTaxString .= $nodes->[$k]->{name} . ';';
    print $k. "\t"
      . $nodes->[$k]->{parent} . "\t"
      . $nodes->[$k]->{rank} . "\t"
      . $nodes->[$k]->{lft} . "\t"
      . $nodes->[$k]->{rgt} . "\t"
      . $nodes->[$k]->{name} . "\t"
      . $thisTaxString . "\n";
    traverseTreeAndPrint( $hash->{$k}, $nodes, $thisTaxString );
  }
}


sub buildTree {
  my ( $tree, $nodes, $taxids, $ranksRef ) = @_;

  foreach my $node (@$nodes) {
    next unless ($node);
    next unless ( $node->{rank} eq 'species' or $node->{rank} eq 'no rank' or $node->{rank} eq 'subspecies');
    
    if(defined($taxids)){
      if($taxids->{$node->{taxid}}){
        $taxids->{$node->{taxid}}->{ncbi_name} = $node->{name};
        $taxids->{$node->{taxid}}->{found} = 1;
        $node->{UPid} = $taxids->{$node->{taxid}}->{UPid};
      }else{
        next;
      }
    }

    my @speciesNodes;
    push( @speciesNodes, $node );
    my $pnode = $node;
    until ( $pnode->{parent} == $pnode->{taxid} ) {
      if( $ranksRef->{ $nodes->[ $pnode->{parent} ]->{rank} } ){
        $speciesNodes[-1]->{parent} = $nodes->[ $pnode->{parent} ]->{taxid};
        push( @speciesNodes, $nodes->[ $pnode->{parent} ] );
      }
      $pnode = $nodes->[ $pnode->{parent} ];
    }

    my $parent = $tree;
    #Now walk down buiding up the tree.
    for ( my $i = $#speciesNodes ; $i >= 0 ; $i-- ) {
      $parent->{ $speciesNodes[$i]->{taxid} } = {}
        unless exists $parent->{ $speciesNodes[$i]->{taxid} };
      $parent = $parent->{ $speciesNodes[$i]->{taxid} };
    }
  }

}


#-------------------------------------------------------------------------------

sub usage {

  print <<'EOF_help';
Usage: $0 

Build a database table of the taxonomic tree using the ncbi taxonomy files names.dmp and nodes.dmp

EOF_help

}

#-------------------------------------------------------------------------------



