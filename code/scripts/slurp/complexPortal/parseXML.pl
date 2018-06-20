#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use XML::XPath;
use XML::XPath::XMLParser;
use GenomeProperties;
use GenomeProperties::Definition;
use GenomeProperties::Step;
use GenomeProperties::StepEvidence;

use LWP::Simple;
use JSON;
use DDP;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );


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


my $data;

$data->{AC} = "GenPropXXXX";
$data->{TP} = "COMPLEX";
$data->{AU} = "Complex Portal";

my $xp = XML::XPath->new(filename => '/Users/rdf/Documents/InterPro/Projects/GenomeProperties/CPX-2107.xml');

my $ins = $xp->find("/entrySet/entry/interactionList/abstractInteraction/names/alias[\@type='complex recommended name']");
foreach my $e ($ins->get_nodelist){
  $data->{DE} = $e->string_value;
  last;
}

my $ipns = $xp->find("/entrySet/entry/interactionList/abstractInteraction/xref/secondaryRef[\@db='pubmed']");
my $rn = 1;
foreach my $e ($ipns->get_nodelist){
  my $pmid = $e->getAttribute("id");
  my $url = "https://www.ebi.ac.uk/europepmc/webservices/rest/search?format=json&query=ext_id:$pmid";

  my $content;
  my $response = $ua->get($url);
  if ( $response->is_success ) {
     $content = $response->decoded_content;
  } else {
    die $response->status_line;
  }
  my $ref = from_json($content);

  foreach my $refObj (@{$ref->{resultList}->{result}}){
    next unless $refObj->{pmid} == $pmid;
    $refObj->{authorString} =~ s/(\.)$//;
    push(@{$data->{REFS}}, { RN => $rn, 
                             RM => $pmid, 
                             RT => $refObj->{title}, 
                             RA => $refObj->{authorString}, 
                             RL => $refObj->{journalTitle}.". ".$refObj->{pubYear}.";".$refObj->{journalVolume}.":".$refObj->{pageInfo}
  });
    $rn++;
  }
}

#Capture the Complex protal accession, which is names as id in the XML.
my $icpns = $xp->find("/entrySet/entry/interactionList/abstractInteraction/xref/secondaryRef[\@db='complex portal']");
foreach my $e ($icpns->get_nodelist){
  push(@{$data->{DBREFS}}, {db_id => "Complex Portal", db_link=> $e->getAttribute("id")});
}

#Now add wwpdb cross references
my $ipdbns = $xp->find("/entrySet/entry/interactionList/abstractInteraction/xref/secondaryRef[\@db='wwpdb']");
foreach my $e ($ipdbns->get_nodelist){
  push(@{$data->{DBREFS}}, {db_id => "PDBe", db_link=> $e->getAttribute("id")});
}

#Fetch out the curated abstract about the complex.
my $icns = $xp->find("/entrySet/entry/interactionList/abstractInteraction/attributeList/attribute[\@name='curated-complex']");
foreach my $e ($icns->get_nodelist){
  $data->{CC} .= $e->string_value;
  $data->{CC} =~ s/\r|\n//g;
}

#Information for the steps
my $ns = $xp->find('/entrySet/entry/interactorList/interactor');


my $size =0;
my $stepNp = 0;
my @fasta;
foreach my $node ($ns->get_nodelist) {
  my $isProtein;
  my $fasta;
  my $primary = $xp->find('./xref/primaryRef', $node);
  foreach my $p ($primary->get_nodelist){
    if($p->getAttribute("db") eq "uniprotkb"){
      my $acc = $p->getAttribute("id")."\n";
      chomp($acc);
      $size++;
      $isProtein++;
      #Now fetch the UniProt accession
      
      my $url = "http://www.uniprot.org/uniprot/$acc.fasta";
      my $response = $ua->get($url);
      if ( $response->is_success ) {
        $fasta = $response->decoded_content;
      } else {
        die $response->status_line;
      }

    }
  }
  next unless($isProtein);
  $stepNp++;
  $fasta =~ s/^(>\S+)/$1 \(Step num\: $stepNp\)/;
  push(@fasta, $fasta);
  my $step;
  $step->{SN} = $stepNp;
  my $fullName = $xp->find('./names/fullName', $node);
  foreach my $fn ($fullName->get_nodelist){
    $step->{ID} = $fn->string_value;
  }




  $step->{RQ} = 1;
  my $second = $xp->find("./xref/secondaryRef[\@db='interpro']", $node);
  foreach my $p ($second->get_nodelist){
    push(@{$step->{EVID}}, { ipr => $p->getAttribute("id"), sig => "xxx", sc => "sufficient"}); 
  }
  push(@{$data->{STEPS}}, $step);
}
$data->{TH} = $size - 1;


#Assume that we have parsed a DESC file into the appropriate data structure.
$gp->fromDESC($data);
#Now write it out again.
$gp->toDESC;

#Now print the fasta file. Note this requires some attention when looping.
open(FA, ">", "fasta") or die "Could not open fasta:[$!]\n";
foreach my $f (@fasta){
  print FA $f;
}
close(FA);
