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


my $iprTSV = "interpro_entry2method_20180620.tsv";
#ENTRY_AC        ENTRY_TYPE      METHOD_AC
#IPR000001       D       PF00051
#IPR000001       D       PS50070
#IPR000001       D       SM00130
#IPR000001       D       cd00108

open(I, "<", $iprTSV) or die "Could not open the interpro TSV file, $iprTSV\n"; 
my $iprs;
while(<I>){
  next unless( /^IPR/); 
  chomp;
  my($acc, $type, $method) = split(/\s+/, $_);
  push(@{ $iprs->{$type}->{$acc} }, $method);
}
close(I);

#my $cpUrl = "ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/current/psi30/ecoli";
#my $cpUrl = "ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/current/psi30/yeast";

my $cpUrl = "ftp://ftp.ebi.ac.uk/pub/databases/intact/complex/current/psi30/human";

my $content;
my $response = $ua->get($cpUrl);
if ( $response->is_success ) {
  $content = $response->decoded_content;
} else {
  warn $response->status_line;
  $content = $response->decoded_content;
  print STDERR "$content\n";
  die;
}



my $outDir = "/tmp/GP";
foreach my $line (split(/\n/, $content)){
  my @row = split(/\s+/, $line);
  my $file = pop(@row);
  p($file);
  next if(-e "$outDir/$file");
  
  mkdir("/tmp/GP/$file");
  chdir("/tmp/GP/$file") or die "Could not change into /tmp/GP/$file:[$!]\n";
   
  my $xmlContent;
  my $response = $ua->get("$cpUrl/$file");
  if ( $response->is_success ) {
    $xmlContent = $response->decoded_content;
  } else {
    die $response->status_line;
  }


  
  my $gp = GenomeProperties->new;

  my $data;

  $data->{AC} = "GenPropXXXX";
  $data->{TP} = "COMPLEX";
  $data->{AU} = "Complex Portal";


  my $xp = XML::XPath->new(xml => $xmlContent);

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
                             RL => $refObj->{journalTitle}.". ".$refObj->{pubYear}.";".$refObj->{journalVolume}.":".
                             (defined($refObj->{pageInfo})? $refObj->{pageInfo} : "-") });
    $rn++;
  }
}

#Capture the Complex protal accession, which is named as id in the XML.
my $cpid;
my $icpns = $xp->find("/entrySet/entry/interactionList/abstractInteraction/xref/secondaryRef[\@db='complex portal']");
foreach my $e ($icpns->get_nodelist){
  push(@{$data->{DBREFS}}, {db_id => "Complex Portal", db_link=> $e->getAttribute("id")});
  $cpid = $e->getAttribute("id");
}

my @go;
my $gns = $xp->find("/entrySet/entry/interactionList/abstractInteraction/xref/secondaryRef[\@db='go']");
foreach my $e ($gns->get_nodelist){
  next if($e->getAttribute("refType") eq "component"); 
  push(@go, $e->getAttribute("id")."-".$e->getAttribute("refType"));
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
          warn "$acc not matched\n";
          $fasta = ">$acc NOT MATCHED\n";
#print "$acc returned ".$response->status_line."\n";
#        die;
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
  foreach my $t (qw(F D R)){
    my $found =0;
    foreach my $p ($second->get_nodelist){
      my $thisIpr = $p->getAttribute("id");
      if($iprs->{$t}->{$thisIpr}){
        $found++;
        foreach my $sig (@{ $iprs->{$t}->{$thisIpr} }){
          push(@{$step->{EVID}}, { ipr => $thisIpr, sig => $sig, sc => "sufficient"}); 
        }
      }
    }
    last if $found;
  }
  push(@{$data->{STEPS}}, $step);
}
$data->{TH} = $size - 1;


#Assume that we have parsed a DESC file into the appropriate data structure.
$gp->fromDESC($data);
#Now write it out again.
$gp->toDESC;

#Now print the fasta file. Note this requires some attention when looping.
open(FA, ">", "FASTA") or die "Could not open FASTA:[$!]\n";
foreach my $f (@fasta){
  print FA $f;
}
close(FA);


open(S, '>', "status") or die "Could not open status file:[$!]\n";
print S "checked:\t0\npublic:\t0\n--\n";
close(S);


open(G, '>', "GOterms") or die "Can not open GOterms file\n";
print G "$cpid\n";
foreach my $g (@go){
  print G "$g\n";
}
close(G);

}
