package GenomePropertiesMeta;	

use strict;
use warnings;
use Data::Printer;
use Carp;
use GenomeProperties::DefinitionMeta;
use GenomeProperties::StepMeta;
use GenomeProperties::StepEvidence;
use GenomePropertiesIO;
use Text::Wrap;
use LWP::Simple;
use JSON;
use List::Uniq ':all';

##         New         ##

sub new {
  my $class = shift;
  
  my $self = {};
  $self->{debug}          = 0;
  $self->{read_sig}       = 0;

   $self->{_skip}          = { CATEGORY => 1, ROOT => 1, SUMMARY => 1 };
  
  bless( $self, $class);  
  return $self;
}

##     Set options     ##

sub set_options {
  my($self, $options, $role) = @_;

  #Check the inputs are logical. 
  if(!$options->{seqs_dir} and !$options->{matches_dir} and !$self->{seqs_dir} and !$self->{matches_dir} and $role eq 'cal'){
    croak("Need either a sequence folder or match folder"); 
    }
  
  croak("Need the extesion of the files")  if (!$options->{ext} and !$self->{ext} and $role eq 'cal');

  my $input = 0;
  $input++ if (defined($options->{all}));
  $input++ if ($options->{list});
  $input++ if ($options->{property});
   
  if ($input > 1){
	die "Only one form of input please\n";
    }
  elsif($input == 0){
	die "Please provide a form of input\n";
    }
  
  foreach my $k (keys %{$options}){
    $self->{$k} = $options->{$k};
    }

  die "Please provide a GenomeProperties path and flatfile\n" if(!$options->{gpdir} or !$options->{gpff});
  die "Please provide an output file\n" if(!$options->{name});
  return 1;
  }

##  Open output files  ##

sub open_outputfiles {
  my ($self) = @_;
    
  #LONGFORM_REPORT_1005058 TABLE_1005058 SUMMARY_FILE_1005058  
  $self->{outdir} = "." if(!defined($self->{outdir}));  
  my $root = $self->{outdir};
   
  #Open 
  foreach my $f (@{$self->{outfiles}}){
    warn "Opening filehandle based on $f\n";
    if($f eq 'long'){
      my $file = $root."/LONGFORM_META_REPORT_".$self->{name};
      open(my $fh, '>', $file) or die "Failed to open $file:[$!]\n";
      $self->longFH($fh);
      }
    elsif($f eq 'summary'){
      my $file = $root."/SUMMARY_META_FILE_".$self->{name};
      open(my $fh, '>', $file) or die "Failed to open $file:[$!]\n";
      $self->summaryFH($fh);
      }
    elsif($f eq 'table'){
      my $file = $root."/TABLE_META_".$self->{name};
      open(my $fh, '>', $file) or die "Failed to open $file:[$!]\n";
      $self->tableFH($fh);
      }
    elsif($f eq 'comp_table'){
      my $file = $root."/COMP_TABLE_META_".$self->{name};
      open(my $fh, '>', $file) or die "Failed to open $file:[$!]\n";
      $self->compTableFH($fh);
      }
    elsif($f eq 'web_json'){
      my $file = $root."/JSON_META_".$self->{name};
      open(my $fh, '>', $file) or die "Failed to open $file:[$!]\n";
      $self->jsonFH($fh);
      }
    elsif($f eq 'match'){
      my $file = $root."/MATCHES_META_".$self->{name};
      open(my $fh, '>', $file) or die "Failed to open $file:[$!]\n";
      $self->matchFH($fh);
      }
    else{
      die "Unknown output type $f\n";
      }
    }
  }

sub longFH {
  my ( $self, $fh ) = @_;
  if($fh){
    if(ref($fh) eq "GLOB"){
      $self->{longFH} = $fh;    
      }
    else{
      croak("Filehandle not passed in\n"); 
      }
    }
    return ($self->{longFH});
  }

sub summaryFH {
  my ( $self, $fh ) = @_;
  if($fh){
    if(ref($fh) eq "GLOB"){
      $self->{summaryFH} = $fh;    
      }
    else{
      croak("Filehandle not passed in\n"); 
      }
    }
    return ($self->{summaryFH});
  }

sub tableFH {
  my ( $self, $fh ) = @_;
  if($fh){
    if(ref($fh) eq "GLOB"){
      $self->{tableFH} = $fh;    
      }
    else{
      croak("Filehandle not passed in\n"); 
      }
    }
    return ($self->{tableFH});
  }

sub compTableFH {
  my ( $self, $fh ) = @_;
  if($fh){
    if(ref($fh) eq "GLOB"){
      $self->{compTableFH} = $fh;    
      }
    else{
      croak("Filehandle not passed in\n"); 
      }
    }
    return ($self->{compTableFH});
  }

sub jsonFH {
  my ( $self, $fh ) = @_;
  if($fh){
    if(ref($fh) eq "GLOB"){
      $self->{jsonFH} = $fh;    
      }
    else{
      croak("Filehandle not passed in\n"); 
      }
    }
    return ($self->{jsonFH});
  }

sub matchFH {
  my ( $self, $fh ) = @_;
  if($fh){
    if(ref($fh) eq "GLOB"){
      $self->{matchFH} = $fh;    
      }
    else{
      croak("Filehandle not passed in\n"); 
      }
    }
    return ($self->{matchFH});
  }

##   Read properties   ##

sub read_properties {
  my($self) = @_;
  
  #I can't find the method to read the gps from a db!
  if($self->gp_source eq 'file'){
    $self->_read_properties_from_flatfile
    }
  elsif($self->gp_source eq 'db'){
    $self->_read_properties_from_db 
    }
  else{
    croak("No source for genome properties.");
    }
  #See if we have been told about an execution order for the GPs.
  #This is important as some GP rely in others.  Otherwise, we will
  #run iteratively. 
  $self->set_execution_order(); 
  }

sub gp_source {
  my ($self) = @_;
  my $s = 'file';
  $s = 'db' if($self->{db});
  return($s);
  }

sub _read_properties_from_flatfile{
  my ( $self ) = @_;

  if( -e $self->_gp_flatfile){
    if( -s $self->_gp_flatfile ){ 
      GenomePropertiesIOMeta::parseFlatfile($self, $self->_gp_flatfile);   
      }
    else{
      croak("The genome properties file has no size ".$self->_gp_flatfile."\n");
      }
    }
  else{
    croak("The geneome properties file, ".$self->_gp_flatfile." does not exist.\n");
    }
  }

sub _gp_flatfile {
  my ( $self ) = @_;
  return($self->{gpdir}.'/'.$self->{gpff});
  }

sub set_execution_order {
  my ($self) = @_;
  if(!defined($self->{execution_order})){
     my $order;
     #If we have a db connection, use this
     #If we have an order file use that
     #Else, just use the sorted list of accessions.
     if($self->gp_source eq 'file' and $self->_order_file){
       $order = $self->_read_order_from_file;
       }
     elsif($self->gp_source eq 'db'){
       $order = $self->_read_order_from_db;
       }
    else{
      #No order, so we will have to rely on iterative execution.
      $order = [ sort{ $a cmp $b } keys(%{$self->{properties}}) ];
      }

    #set it in the object.
    $self->{execution_order} = $order;
    }

  return($self->{execution_order});
  }

sub _order_file {
  my ($self) = @_;
  return($self->{eval_order});
  }

sub _read_order_from_file {
  my ($self) = @_;

  my @order;
  open(my $FH, '<', $self->_order_file) or croak("Failed to open order file:".$self->_order_file."\n");
  while(<$FH>){
    chomp;
    push(@order, $_);
    }
  close($FH);
  return(\@order);
  }

sub fromDESC {
  my ($self, $data ) = @_;
  my $gpd = GenomeProperties::DefinitionMeta->new( {'accession' => $data->{AC},
                           'type'      => $data->{TP},
                           'name'      => $data->{DE},
                           'map'       => '',
                           'public'    => 1,
                           'threshold' => $data->{TH},
                           'author'    => $data->{AU},
                           'method'    => 'SIMPLE',
                           'parents'   => $data->{PARENT},
                           'comment'   => $data->{CC}, #Previously call description.
                           'private'   => $data->{private}});

  $gpd->refs($data->{REFS}) if ($data->{REFS});
  $gpd->dbrefs($data->{DBREFS}) if ($data->{DBREFS});
  my $order = 0;
  my $seenSteps;
  
  foreach my $step (@{$data->{STEPS}}){
    $order++;
    if(defined( $seenSteps->{ $step->{SN} } )){
      die("Duplicate step number ".$step->{SN}."\n");
      }
    else{
      $seenSteps->{ $step->{SN} }++;
      }
    
    my $stepObj = GenomeProperties::StepMeta->new({ order        => $step->{SN},
                                                step_name    => $step->{ID},
                                                required     => $step->{RQ},
                                                in_rule      => 1,
                                                alter_name   => $step->{DN} }
                                                );
    $gpd->add_step($stepObj);
    foreach my $ev (@{$step->{EVID}}){
      my $evObj;
      if($ev->{gp}){
        $evObj = GenomeProperties::StepEvidence->new( {
                                                      genome_property => $ev->{gp}
                                                      } );
        }
      else{
        $evObj = GenomeProperties::StepEvidence->new( {
                                                      interpro   => $ev->{ipr},
                                                      accession  => $ev->{sig},
                                                      type       => $ev->{sc},
                                                      get_go     => $ev->{go}
                                                      } );
        }
      $stepObj->add_evidence($evObj);
      } 
    }
  $self->add_def($gpd);
  }
  
sub add_def {
  my ($self, $def) = @_; 
  # add the property to a hash, indexed by accession
  #add mapping key if present
  #map according to category
  $self->{properties}->{$def->{accession}} = $def;
  $self->{_defmap}->{$def->{map}}  = $def->{accession};
  $self->{_defcat}->{$def->{type}} = $def->{accession};
  }  
  
## Define sequences set ##

sub define_sequence_set {
  my($self, $seq_blob) = @_;
  my @sb;
  if($seq_blob){
    @sb = split(/\n/, $seq_blob);
    foreach my $r (@sb){
      }
    }
  else{  
    #open and read the sequences folder
    opendir my $dh, $self->{seqs_dir} or crack ( "Failed to open ".$self->{seqs_dir}."\n");
    while (my $file = readdir $dh) {
      next if (!$file =~ /$self->{ext}$/);
      open(my $FH, '<', $file) or croak( "Failed to open ".$file."\n");
      @sb = <$FH>; 
      $file =~ s/^$self->{seqs_dir}(.*?)\.$self->{ext}$//;
      my $prot = $1;
      foreach my $l (@sb){
        $self->{seqs_and_annotations}->{$prot}->{$1} = [] if($l =~ /^>(\S+)/);
        }
      }  
    }
  }
##       Annotate      ##
  
sub annotate_sequences {
  my($self) = @_;

  #Read from match file if defined
  die "Can only run using pre-calculated i5 output\n" unless ($self->signature_matches);

  $self->transform_annotations;
  $self->annotated(1);
  }

sub signature_matches {
  my ($self) = @_;
  
  if(!$self->{read_sig} && $self->{matches_dir}){
    my @mb;
    opendir my $dh, $self->{matches_dir} or crack ( "Failed to open ".$self->{matches_dir}."\n");
    while (my $file = readdir $dh) {
      my $ext = $self->{ext};
      next if ($file !~ /$ext$/);
      $file =  $self->{matches_dir}."/".$file;
      open(my $FH, '<', $file) or die "Could not open signature matches file: ".$file."\n";
      $file =~ s/^$self->{matches_dir}\/(.*?)\.$self->{ext}$//;
      my $prot = $1;
      @mb = <$FH>;
      close($FH);
      foreach my $line (@mb){
        chomp($line);
        my @i5 = split(/\t/, $line);
        push(@{ $self->{seqs_and_annotations}->{$prot}->{$i5[0]} }, $i5[4]);
        }
      }
      $self->{read_sig} =1;  
    }
  return $self->{read_sig};
  }

sub transform_annotations {
  my ($self) = @_; 
  my %fams;
  foreach my $prot (keys %{$self->{seqs_and_annotations} }){
    foreach my $seq (keys %{$self->{seqs_and_annotations}->{$prot} }){
      foreach my $fam (@{ $self->{seqs_and_annotations}->{$prot}->{$seq} }){
        push (@{$fams{$fam}->{$seq}}, $prot);
        }
      }
    }
  $self->families(\%fams);
  }

sub families{
  my ($self, $fams) = @_;
  $self->{families} = $fams if($fams);
  return($self->{families});
  }

sub annotated {
  my $self = shift;
  my $state = shift;
  $self->{annotated} = 1 if(defined($state));
  return ($self->{annotated});
  }
 
##      Evaluation     ##

sub evaluate_properties {
  my ($self) = @_;  

  #GP can require other genome properties. We therefore need to
  #recursively search them, until all are evaluated.
  $self->incomplete(1);
  while ($self->incomplete) {
	$self->check_results();
    }
  return 1;
  }
 
sub incomplete {
  my($self, $value) = @_;
  $self->{incomplete} = $value if(defined($value));
  return($self->{incomplete});
  } 

sub check_results{
  my($self) = @_;
  my @prop_list = keys(% { $self->get_defs });  
  my $miss = 0;
  foreach my $acc (@prop_list){
    #Some property types are not required to be evaluated.
    #The only ones that will be skipped as it is, are "CATEGORY", "ROOT" and "SUMMARY"
    next if ( $self->skip_def( $self->get_def($acc)->type )); 
    
    #Evaluate the property, two scenarios, not tested, or tested and it had an unevaluated dependency
    if (!defined($self->get_def($acc)->evaluated) or $self->get_def($acc)->evaluated == 0 ){
      $self->evaluate_property($acc);	  
	  #We should have evaluated the property, unless it has an unevaluated deps.
      if ($self->get_def($acc)->evaluated == 0 ){
	    $miss++;
        if ($self->{debug}) {
          print "$acc is still missing\n";
          print "value of missing: $miss\n";
          }
	    }
      }
    }   
  print "MISSING is $miss <-----------------------------------\n" if ($self->{debug});
  $self->incomplete(0) if ($miss == 0);
  }


sub get_defs {
  my ($self) = @_;
  return($self->{properties});
  }

sub skip_def{
  my ($self, $type) = @_;
  croak("No property type passed in!\n") if(!$type);
  
  my $skip = 0;
  $skip = 1 if(defined( $self->{_skip}->{$type} ));  
  
  return $skip;
  }
  
sub get_def {
  my ($self, $acc) = @_;
  carp("No accession passed in.\n") if(!$acc);
    
  if(!defined($self->{properties}->{$acc})){
    carp("No property found for this accession ($acc)\n");  
    return 0;
    }
  else{
    return($self->{properties}->{$acc});
    }
  }
  
sub evaluate_property {
  my($self, $acc) = @_; 
  my %found;
  my @missing;
  my @members;
  print "In evaluate property, $acc\n" if ($self->{debug});

  my $def = $self->get_def($acc);
  $def->evaluated(1);
  foreach my $step (@{ $def->get_steps }){
    print "Working on step: ".$step->order."\n" if ($self->{debug});
    $self->evaluate_step($step);

    #If we were not able to evaluate the step, bail
    if($step->evaluated == 0){
      $def->evaluated(0);
      return;
      }
    if($step->{found}){
      $found{$step->{order}} = $step->found;
      }
    elsif($step->required and $step->skip != 1){
      push (@missing, $step);
      }    
    }
  #Three possible results for the evaluation
  if(scalar (keys %found) == 0 or scalar (keys %found) <= $def->threshold){
    $def->result('NO'); #No required steps found
    }
  elsif(scalar @missing > 0){
    $def->result('PARTIAL'); #One or more required steps found, but one or more required steps missing
    }
  else{
    $def->result('YES'); #All steps found.
    }

  if(scalar (keys %found) > $def->threshold){
    foreach my $step (keys %found){
      push (@members, @{$found{$step}});
      }
    @members = uniq(@members);
    $def->members(@members);
    }
  } 
  
sub evaluate_step {
  my($self, $step) = @_;
  my @succeed;

  $step->evaluated(1);
  print "Evaluating ".$step->step_name."\n" if ($self->{debug});
  my $evRef = $step->get_evidence;
  
  if (!scalar(@{$evRef})){
    print ("\tthis step has no evidence\n") if ($self->{debug});
    $step->skip(1);
    }
  else {
    EV: foreach my $evObj (@{$evRef}){
    #if (!$ev_id) {print RESULTS ("there is no ev_id\n"); next;} - Add to the object method
      if (defined $evObj->interpro){
        print "\tevidence is ".$evObj->interpro."\n" if ($self->{debug});
        print "\tev type is: ".$evObj->type."\n" if ($self->{debug});
        }
      elsif (defined $evObj->gp){
        print "\tevidence is ".$evObj->gp."\n" if ($self->{debug});
        }
      else {
        print "\tevidence is ".$evObj->{sig}."\n" if ($self->{debug});
        }        
      if($evObj->gp){
        if(defined($self->get_defs->{ $evObj->gp })){
          # For properties a PARTIAL or YES result is considered success           
          if( $self->get_defs->{ $evObj->gp }->result eq 'YES' or $self->get_defs->{ $evObj->gp }->result eq 'PARTIAL' ){
              push (@succeed, @{$self->get_defs->{ $evObj->gp }->members});
            }
          elsif($self->get_defs->{ $evObj->gp }->result eq 'UNTESTED'){
            $step->evaluated(0);  
            }
          }
        }
      elsif($evObj->interpro){
        #Need to annotated the sequences  
        $self->annotate_sequences if (!$self->annotated);
        #See if the accession has been found  
        if($self->get_family($evObj->accession) and $self->{families}{$evObj->accession} != 0) {
          foreach my $k (keys % {$self->{families}{$evObj->accession}}) {
            push @succeed, $self->{families}{$evObj->accession}{$k}; 
            }
          @succeed = uniq(@succeed);
          last EV;
          }
        }
      else{
        die "unknown evidence object type\n";
        }
      }
    }
  
  if (scalar @succeed > 0){
    $step->found(@succeed);
    #$step->matched_sequences($mSeqs);
    #Need to get the sequences in here. 
    }
  }

sub get_family {
  my ($self, $acc) = @_;
  if(defined ($self->{families}) and defined ($self->{families}{$acc})){
    return $self->{families}{$acc};
    }
  else{
    return 0; 
    }
  }

##        Write        ##

sub write_results{
  my ( $self ) = @_;
  #Only the table file has a header line
  if($self->tableFH){
    my $fh = $self->tableFH;
    print $fh  "acc\tdescription\tproperty_value\tstep_number\tstep_name\tstep_value\trequired?\tevidence_type\tevidence_name\tbest_HMM_hit\tHMM_hit_count\n";
    }
  
  foreach my $acc (sort{$a cmp $b}keys(% { $self->get_defs })){
    my $prop = $self->get_def($acc);
    next if(defined( $self->{_skip}->{ $prop->type } ));
    $self->print_summary($prop) if($self->summaryFH and fileno($self->summaryFH));
    $self->print_long($prop) if($self->longFH);
    $self->print_table($prop) if($self->tableFH);
    $self->print_compressed_table($prop) if($self->compTableFH);
    $self->build_json($prop) if($self->jsonFH);
    $self->print_matches($prop) if($self->matchFH);
    }

  $self->print_json if($self->jsonFH);
  return(1);
  }

sub print_summary {
  my ($self, $prop) = @_;
  my $report = $prop->accession."\t".$prop->name."\t".$prop->result."\n";
  my $fh = $self->summaryFH;
  print $fh $report;
  }

sub print_long {
  my($self, $prop) = @_;
  my $report = "PROPERTY: ".$prop->accession."\n";
  $report .= $prop->name."\n";
  #TODO switch sort to <=>, once orders are replaced.
  foreach my $step (sort { $a->order cmp $b->order} @{ $prop->get_steps }){
    #	print LONGFORM (".\tSTEP NUMBER: $steps{$step_p}[2]\n.\tSTEP NAME: $steps{$step_p}[3]\n");
    $report .= ".\tSTEP NUMBER: ".$step->order."\n";
    $report .= ".\tSTEP NAME: ".$step->step_name."\n";  
    $report .= ".\t.\trequired\n" if (defined($step->required) and $step->required == 1);
    
    foreach my $ev (@{$step->get_evidence}){
      if($ev->interpro){
        $report .= ".\t.\tINTERPRO: ".$ev->interpro."; ".$ev->accession."\n";
        }
      elsif($ev->gp){
        $report .= ".\t.\tGENPROP: ".$ev->gp."\n";
        }
      else{
        warn "Unknown step type\n";
        p($ev);
        }
      }
      
    #TODO: Does this relate to the step or evidence
    if ($step->found) {
      $report .= ".\tSTEP RESULT: ".(join ", ", @{$step->found})."\n";  
      }
    else {
      $report .= ".\tSTEP RESULT: NO\n";
      }
    }
    
  $report .= "RESULT: ".$prop->result."\n";
  if (defined $prop->members) {
    $report .= "MEMBERS: ".(join ",", @{$prop->members})."\n";
    }
  else {
    $report .= "MEMBERS: 0\n";   
    }
  my $fh = $self->longFH;  
  print $fh $report;
  }

sub print_table {
  my ($self, $prop ) = @_; 
#acc     description     property_value  step_number     step_name       step_value      required?       evidence_type   evidence_name   best_HMM_hit    HMM_hit_count
#GenProp0001     chorismate biosynthesis via shikimate   YES     5       shikimate kinase        yes     required        HMM     PF01202 tr|F4HBD8|F4HBD8_GALAU  2
  my ($row, $report); 
  $row = join("\t", $prop->accession, $prop->name, $prop->result);
  foreach my $step (sort { $a->order cmp $b->order} @{ $prop->get_steps }){
    next if($step->skip);
    my $evRef = $step->get_evidence;
    my %et; #Store evidence type
    
    foreach my $e (@{ $step->get_evidence }){
      if($e->gp){
        $et{"Genome Property"}++;
        }
      else{
        $et{"InterPro"}++;
        }
      }
    my $evidence_type = join(",", keys(%et));
    if ($step->found != 0) {
      $report .= $row."\t".$step->order."\t".$step->step_name."\t".(join ",", @{$step->found})."\t".(defined($step->required) ? "YES" : "NO")."\t$evidence_type\n";
      }  
    else{
      $report .= $row."\t".$step->order."\t".$step->step_name."\tMISSING\t".(defined($step->required) ? "YES" : "NO")."\t$evidence_type\n";
      }
    }
  #Now write the report to the filehandle.
  my $tfh = $self->tableFH;
  print $tfh $report;
  }

sub print_compressed_table {

  my ($self, $prop ) = @_; 
  #acc     description     property_value [array of step values]
  #GenProp0001     chorismate biosynthesis via shikimate   [0,Prot1,Prot1|Prot2,-1,Prot2] 
  my ($row, $report); 
  $row = join("\t", $prop->accession, $prop->name, $prop->result);
  my @stepRes;
  foreach my $step (sort { $a->order cmp $b->order} @{ $prop->get_steps }){
    if($step->skip){
      push(@stepRes, -1);    
      }
    elsif($step->found != 0){
      push(@stepRes, join ('|',@{$step->found}));
      }
    else{
      push(@stepRes, 0);    
      }
    }
  
  $row .= "\t[".join(",", @stepRes)."]";
  $row .= "\n";
  #Now write the report to the filehandle.
  my $tfh = $self->compTableFH;
  print $tfh $row;
  }

sub build_json {
  my ( $self, $prop ) = @_;
  my %propj = ( property => $prop->accession,
                name     => $prop->{name},
                values   => { $self->{name} => $prop->result,
                              TOTAL       => { YES     => $prop->result eq 'YES'     ? 1 : 0,
                                               PARTIAL => $prop->result eq 'PARTIAL' ? 1 : 0,
                                               NO      => $prop->result eq 'NO'      ? 1 : 0
                                               }
                              }
                );

  foreach my $step (sort { $a->order cmp $b->order} @{ $prop->get_steps }){
    next if($step->skip);
    push(@{ $propj{steps} }, { "step"       => $step->order,
                               "step_name"  => $step->step_name,
                               "required"   => defined($step->required) ? 1 : 0,
                               "values"     => { $self->{name} => $step->found } });
      }
  $self->{_json}->{$prop->accession}= \%propj;
  return;
  }

sub print_matches {
  my($self, $prop) = @_;


  if($prop->result eq "YES" or $prop->result eq "PARTIAL"){
    my $fh = $self->matchFH;  
    my $pDESC = $prop->accession."\t".$prop->name;
    
    #TODO switch sort to <=>, once orders are replaced.
    foreach my $step (sort { $a->order cmp $b->order} @{ $prop->get_steps }){
      if($step->found != 0){
        my $sDESC = $step->order."\t".$step->step_name."\t";
        $sDESC .= "required" if (defined($step->required) and $step->required == 1);
          
        foreach my $ev (@{$step->get_evidence}){
          my $eDESC;
          my $seenSeq;
          if($ev->interpro){
            if($self->get_family( $ev->accession ) ){
              my @seqs = keys %{ $self->get_family( $ev->accession ) };
              foreach my $s (@seqs){
                #next if($seenSeq->{$s});
                my $report = $ev->interpro."\t".$ev->accession."\t".$s."[".@{$self->get_family( $ev->accession )->{$s}}[0]."]\t";
                print $fh $pDESC."\t$sDESC\t$report\n";
                #$seenSeq->{$s}++;
                #last;
                }
              }
            }
          }
        }
      }
    }
  }
  
sub print_json {
  my ($self) = shift;
  my $jfh = $self->jsonFH;
  print $jfh to_json($self->{_json}, { ascii => 1, pretty => 1 });
  return;
  }

##    Close output     ##

sub close_outputfiles {
  my($self) = @_;
  close($self->longFH)      and  $self->removeLongFH      if ($self->longFH);
  close($self->summaryFH)   and  $self->removeSummaryFH   if ($self->summaryFH); 
  close($self->tableFH)     and  $self->removeTableFH     if ($self->tableFH);
  close($self->compTableFH) and  $self->removeCompTableFH if($self->compTableFH);
  close($self->jsonFH)      if($self->jsonFH);
  close($self->matchFH)     if($self->matchFH);
  return(1);
  }

sub removeSummaryFH {
  my ($self);
  delete $self->{summaryFH};
  }

sub removeCompTableFH {
  my ($self);
  delete $self->{compTableFH};
  }

sub removeTableFH {
  my ($self);
  $self->{tableFH}=undef;
  }

sub removeLongFH {
  my ($self);
  $self->{longFH}=undef;
  }


##        Debug        ##
sub debug{
  my($self, $bool) = @_; 
  $self->{debug} = $bool if($bool);
  return($self->{debug});
  }

1;    
