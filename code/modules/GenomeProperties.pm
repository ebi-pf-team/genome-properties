package GenomeProperties;	

use strict;
use warnings;
use Data::Printer;
use Carp;
use GenomeProperties::Definition;
use GenomeProperties::Step;
use GenomeProperties::StepEvidence;
use Text::Wrap;
use LWP::Simple;
use JSON;


sub new {
  my $class = shift;
  
  my $self = {};
 
  #These defaults can/should be over-ridden. 
  $self->{gpdir}          = "/nfs/production/interpro/genome_properties/data/genome_properties_flatfiles/";
  $self->{hmm_dir}        = "/nfs/production/interpro/genome_properties/data/pfam_and_tigrfam/";
  $self->{project_name}   = "DEFAULT";
  $self->{debug}          = 0;
  $self->{read_sig}       = 0;

  #These should be constants;
  $self->{_skip}          = { CATEGORY => 1, ROOT => 1, SUMMARY => 1 };
  $self->{_prop_def}      = "PROP_DEF.TABLE";
  $self->{_prop_step}     = "PROP_STEP.TABLE";
  $self->{_step_ev_link}  = "STEP_EV_LINK.TABLE";
  
  bless( $self, $class);  
  return $self;
}

sub annotated {
  my $self = shift;
  my $state = shift;

  if(defined($state)){
    $self->{annotated} = 1;
  }
  return ($self->{annotated});
}


sub write_results{
  my ( $self ) = @_;
  #Only the table file has a header line
  if($self->tableFH){
    my $fh = $self->tableFH;
    print $fh  "acc\tdescription\tproperty_value\tstep_number\tstep_name\tstep_value\trequired?\tevidence_type\tevidence_name\tbest_HMM_hit\tHMM_hit_count\tHMM_command\n";
  }
  
  foreach my $acc (sort{$a cmp $b}keys(% { $self->get_defs })){
    #next unless($acc eq 'GenProp0643' or $acc eq 'GenProp0001' or $acc eq 'GenProp0639');
    my $prop = $self->get_def($acc);
    $self->print_summary($prop) if($self->summaryFH);
    $self->print_long($prop) if($self->longFH);
    $self->print_table($prop) if($self->tableFH);
  }
}

  

sub print_summary {
  my ($self, $prop) = @_;
  my $report = $prop->accession."\t".$prop->name."\t".$prop->result."\n";
  
  my $fh = $self->summaryFH;
  print $fh $report;
    
}

sub print_table {
  my ($self, $prop ) = @_; 
#acc     description     property_value  step_number     step_name       step_value      required?       evidence_type   evidence_name   best_HMM_hit    HMM_hit_count
#GenProp0001     chorismate biosynthesis via shikimate   YES     5       shikimate kinase        yes     required        HMM     PF01202 tr|F4HBD8|F4HBD8_GALAU  2
  my ($row, $report); 
  $row = join("\t", $prop->accession, $prop->accession, $prop->result);
 foreach my $step (sort { $a->order cmp $b->order} @{ $prop->get_steps }){
         
   
 }
  my $fh = $self->tableFH;
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
    $report .= ".\t.\trequired\n" if ($step->required == 1);
    
    foreach my $ev (@{$step->get_evidence}){
      if($ev->type eq 'HMM' or $ev->type eq 'HMM-CLUST'){
        $report .= ".\t.\t".$ev->type.": ".$ev->accession."\n";
      }elsif($ev->type eq 'GENPROP'){
        $report .= ".\t.\t".$ev->type.": ".$ev->accession."\n";
      }
    }
    #TODO: Does this relate to the step or evidence
    $report .= ".\tSTEP RESULT: ".($step->found == 1 ? 'yes' : 'no')."\n";
  
  }
    
  

  #print LONGFORM ("PROPERTY: $prop\n$properties{$prop_num}[1]\n\n");
	#print SHORTFORM ("$prop\t$properties{$prop_num}[1]\t");
	#foreach my $step_p (@{$def_step{$prop_num}})
	#{
	#	if ($debug) {print "PRINT: step: $step_p\n";}
	#	print LONGFORM (".\tSTEP NUMBER: $steps{$step_p}[2]\n.\tSTEP NAME: $steps{$step_p}[3]\n");
#		my $already_printed = 0;
#		foreach my $ev_p (@{$step_ev{$step_p}})
#		{
#			$noev = 0;
#			if ($debug) {print "PRINT: ev: $ev_p\n";}
#			print TABLE ("$prop\t$properties{$prop_num}[1]\t");
#			if ($results{$prop} == 2)
#			{
#				print TABLE ("YES\t");
#				if (!$printed_result){print SHORTFORM ("YES\n"); $printed_result=1;}
#			}
#			if ($results{$prop} == 1)
#			{
#				print TABLE ("PARTIAL\t");
#				if (!$printed_result){print SHORTFORM ("PARTIAL\n"); $printed_result=1;}
#			}
#			if ($results{$prop} == 0)
#			{
#				print TABLE ("NO\t");
#				if (!$printed_result){print SHORTFORM ("NO\n"); $printed_result=1;}
#			}
#			print TABLE ("$steps{$step_p}[2]\t$steps{$step_p}[3]\t$steps{$step_p}[5]\t");
#			if (@{$steps{$step_p}}[4])
#			{
#				print TABLE ("required\t");
#				if (!$already_printed)
#				{
#					print LONGFORM (".\t.\trequired\n");
#					$already_printed = 1;
#				}
#			}
#			else
#			{
#				print TABLE ("not required\t");
#				if (!$already_printed)
#				{
#					print LONGFORM (".\t.\tnot required\n");
#					$already_printed = 1;
#				}
#			}
#			print TABLE ("$ev{$ev_p}[3]\t$ev{$ev_p}[2]\t");
#			if ($ev{$ev_p}[3] eq "HMM" || $ev{$ev_p}[3] eq "HMM-CLUST")
#			{
#				if ($ev{$ev_p}[5] ne "0")
#				{
#					my  @split_line = split(/\s+/, $ev{$ev_p}[4]);
#					print TABLE ("$split_line[0]\t$ev{$ev_p}[5]\t$ev{$ev_p}[6]\n");
#				}
#				else
#				{
#					print TABLE ("$ev{$ev_p}[4]\t$ev{$ev_p}[5]\tN/A\n");
#				}
#				print LONGFORM (".\t.\t$ev{$ev_p}[3]: $ev{$ev_p}[2]\n.\t.\tBEST HIT: $ev{$ev_p}[4]\n.\t.\tHIT COUNT: $ev{$ev_p}[5]\n");
#			}
#			elsif ($ev{$ev_p}[3] eq "GENPROP")
#			{
#				print TABLE ("N/A\tN/A\tN/A\n");
#				print LONGFORM (".\t.\t$ev{$ev_p}[3]: $ev{$ev_p}[2]\n");
#			}		
#			else 
#			{
#				print TABLE ("N/A\tN/A\tN/A\n");
#				print LONGFORM (".\t.\t$ev{$ev_p}[3]\n");
#			}
#		}
#		print LONGFORM (".\tSTEP RESULT: $steps{$step_p}[5]\n\n");
#	}
#	if ($noev)
#	{
#		print SHORTFORM ("NO\n");
#	}


  $report .= "RESULT: ".$prop->result."\n";
  my $fh = $self->longFH;  
  print $fh $report;

}	
	
sub open_outputfiles {
  my ($self) = @_;
    
   #LONGFORM_REPORT_1005058 TABLE_1005058 SUMMARY_FILE_1005058  
   if(!defined($self->{outdir})){
    $self->{outdir} = ".";  
   }
   print STDERR $self->{outdir}."\n";
   
   my $root = $self->{outdir};
   foreach my $f (@{$self->{outfiles}}){
      print "$f\n";
      if($f eq 'long'){
        my $file = $root."/LONGFORM_REPORT_".$self->{name};
        my $fh;
        open($fh, '>', $file) or die "Failed to open $file:[$!]\n";
        $self->longFH($fh);
      }elsif($f eq 'summary'){
        my $file = $root."/SUMMARY_FILE_".$self->{name};
        my $fh;
        open($fh, '>', $file) or die "Failed to open $file:[$!]\n";
        $self->summaryFH($fh);
      }elsif($f eq 'table'){
        my $file = $root."/TABLE_".$self->{name};
        my $fh;
        open($fh, '>', $file) or die "Failed to open $file:[$!]\n";
        $self->tableFH($fh);
      }
   }
   
}

sub longFH {
  my ( $self, $fh ) = @_;
  
  if($fh){
    if(ref($fh) eq "GLOB"){
      $self->{longFH} = $fh;    
    }else{
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
    }else{
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
    }else{
      croak("Filehandle not passed in\n"); 
    }
  }
  return ($self->{tableFH});
}

sub close_outputfiles {
  my($self) = @_;
  close($self->longFH) if ($self->longFH);
  close($self->summaryFH) if ($self->summaryFH); 
  close($self->tableFH) if ($self->tableFH);
}
	
sub debug{
  my($self, $bool) = @_; 
  $self->{debug} = $bool if($bool);
  return($self->{debug});
}

sub set_options {
  my($self, $options, $role) = @_;

  #Check the inputs are logical. 
  if(!$options->{seqs} and !$options->{matches} and $role eq 'cal'){
    croak("Need either a sequence file or match file"); 
  }

  my $input = 0;
  if (defined($options->{all})){
    $input++;
  }
  if ($options->{list}){
    $input++;
  }
  
  if ($options->{property}){
    $input++;
  }
  if ($input > 1){
	  die "Only one form of input please\n";
  }elsif($input == 0){
	  die "Please provide a form of input\n";
  }

  foreach my $k (keys %{$options}){
    $self->{$k} = $options->{$k};
  }
  
  #TODO: die on fatal option omitions.
}


sub define_sequence_set {
  my($self) = @_;
  
  #open and read the sequence file
  open(FH, '<', $self->{seqs}) or croak( "Failed to open ".$self->{seqs}."\n");
  while(<FH>){
    if(/^>(\S+)/){
      $self->{seqs_and_annotations}->{$1} = [];
    }
  }

}

sub get_sequence_set {
  my ($self) = @_;
  

  return($self->{seqs_and_annotations});
}

sub annotate_sequences {
  my($self) = @_;

  #Read from match file if defined
  if($self->signature_matches){
    ;
  }else{
    #Run the searches.....ultimately, this will be depricated.
  
  #TODO Replace annotation of sequences.
    #This is a temporary hack and need to be replaced!
    #76-84
    
    my @gp = qw(PF01202
    TIGR01920
    TIGR00033
    TIGR01357
    PF01959
    TIGR00507
    TIGR01809
    TIGR01088
    TIGR01093
    TIGR00034
    TIGR01358
    TIGR01361
    TIGR01949
    TIGR01356
    TIGR00658
    );   
  
    my $i = 0;
    foreach my $s (keys %{$self->{seqs_and_annotations}}){
      push(@{ $self->{seqs_and_annotations}->{$s} }, $gp[$i]);
      $i++;
      $i = 0 if($i > 14);
    }
  }
  $self->transform_annotations;
  $self->annotated(1);
}

sub signature_matches {
  my ($self) = @_;
  
  if(!$self->{read_sig} && $self->{matches}){
    open(FH, '<', $self->{matches}) or die "Could not open signature file\n";
    while(<FH>){
      chomp;
      my($family, $s) = split(/\t/, $_);
      push(@{ $self->{seqs_and_annotations}->{$s} }, $family);
    }
    close(FH);
    $self->{read_sig} =1;  
  }
  
  return $self->{read_sig};
  
}

sub transform_annotations {
  my ($self) = @_; 
  
  my %fams;
  foreach my $seq (keys %{$self->{seqs_and_annotations} }){
    foreach my $fam (@{ $self->{seqs_and_annotations}->{$seq} }){
      push(@{$fams{$fam}}, $seq); 
    }
  }
  $self->families(\%fams);
}

sub families{
  my ($self, $fams) = @_;
  
  if($fams){
    $self->{families} = $fams;  
  }  
  
  return($self->{families});
}

sub get_family {
  my ($self, $acc) = @_;
  
  if(defined ($self->{families}) and defined ($self->{families}->{$acc})){
    return $self->{families}->{$acc};
    
  }else{
    return 0; 
  }
}

sub evaluate_properties {
  my ($self) = @_;  

  #GP can require other genome properties. We therefore need to
  #recursively search them, until all are evaluated.
  $self->incomplete(1);
  while ($self->incomplete) {
	  $self->check_results();
  }
}


sub incomplete {
  my($self, $value) = @_;
  
  if(defined($value)){
    $self->{incomplete} = $value;
  }
  
  return($self->{incomplete});
}

sub skip_def{
  my ($self, $type) = @_;
  
  if(!$type){
    croak("No property type passed in!\n");  
  }
  my $skip = 0;
  if(defined( $self->{_skip}->{$type} )){
    $skip = 1;  
  }
    
  return $skip;
}

sub check_results{
  my($self) = @_;
	
  my @prop_list = keys(% { $self->get_defs });  
  
#my @prop_list = ('GenProp0001', 'GenProp0643', 'GenProp0639');#

  #my @prop_list = ('GenProp0016');
  my $miss = 0;
  foreach my $acc (@prop_list){
    #Some property types are not required to be evaluated
    next if ( $self->skip_def( $self->get_def($acc)->type )); 
    
    #Evaluate the property, two scenarios, not tested, or tested and it had an unevaluated dependency
    if (!defined($self->get_def($acc)->evaluated) or $self->get_def($acc)->evaluated == 0 ){
		  $self->evaluate_property($acc);
		  
		  
		  #We should have evaluated the proprtery, unless it has an unevaluated deps.
      if ($self->get_def($acc)->evaluated == 0 ){
				$miss++;
			  if ($self->debug) {
          print "$acc is still missing\n";
			    print "value of missing: $miss\n";
        }
			}
		} 
	}
	
  if ($self->debug) {
    print "MISSING is $miss <-----------------------------------\n";
  }
  if($miss == 0){
    $self->incomplete(0);
  }
}


sub evaluate_property {
  my($self, $acc) = @_; 

	my $found = 0;
	my $missing = 0;

  if($self->debug){
    print "In evaluate proptery, $acc\n";
  }
  my $def = $self->get_def($acc);
  $def->evaluated(1);
  foreach my $step (@{ $def->get_steps }){
    if($self->debug){
      print "Working on step:".p($step)."\n";
    }

    $self->evaluate_step($step);

    #If we were not able to evaluate the step, bail
    if($step->evaluated == 0){
      $def->evaluated(0);
      return;
    }
    
    if($step->found){
      $found++;
    }elsif($step->required and $step->skip != 1){
      $missing++
    }
  }
  
  #Three possible results for the evaluation
  if($found == 0){
    $def->result('NO'); #No required steps found
  }elsif($missing){
    $def->result('PARTIAL'); #One or more required steps found, but one or more required steps missing
  }else{
    $def->result('YES'); #All steps found.
  }
}



sub evaluate_step {
  my($self, $step) = @_;
	my $succeed = 0;
	my $some_evidence = 0; #Indicates whether the step is associated with some evidence, not really required.
  
  #We need to know if this step have been evaluated. If it has a dependency on the another GP, that
  #has not been tested at this point, we will set this to being 0. Note, for steps with no evidence,
  #this remains true, but there is nothing to evaluate against.
  $step->evaluated(1);
	if ($self->debug) {
      print "Evaluating ".$step->step_name."\n";
  }
  my $evRef = $step->get_evidence;
	
	#
	if (!scalar(@{$evRef})){
    if($self->debug){
      print ("\tthis step has no evidence\n");
    }
    $step->skip(1);
	} else {
	
		EV: foreach my $evObj (@{$evRef}){
			#if (!$ev_id) {print RESULTS ("there is no ev_id\n"); next;} - Add to the object method
			if ($self->debug) {print ("\tevidence is ".p($evObj)."\n");}
			if ($self->debug) {print "\tev type is: ".$evObj->type."\n";}
			if ($evObj->type eq "RULE_BASE")																		#if the type is RULE_BASE
			{
				#TODO print RESULTS ("\tUNABLE TO EVALUATE EVIDENCE TYPE RULE_BASE. MARKING STEP AS NOT FOUND\n");					#warn that RULE_BASE cannot be evaluated at this time
				next;
			}	elsif (($evObj->type eq "HMM") || ($evObj->type eq "HMM-CLUST")){
				#TODO print RESULTS ("\tSEARCHING HMM $ev{$ev_id}[2]\n");
				if ($evObj->type eq "HMM-CLUST"){
					#TODO print RESULTS ("\tWARNING: DISTANCE CHECKING NOT CURRENTLY IMPLEMENTED. ONLY CHECKING HMM HIT\n");
				  #TODO Once working on DNA, will need to determine how to do this.
				}

        #Need to 
        if(!$self->annotated){  
				  $self->annotate_sequences
        }

        if($self->get_family( $evObj->accession ) ){
						  $succeed++;
						  last EV;
        }
        #Loop over the annotate_sequences
        #TODO Incredible inefficient. Transform once. Then we have counts and best scores.
        #foreach my $seqAcc (keys(%{ $self->get_sequence_set })){
        #    if($annotation eq $evObj->accession){
        #   foreach my $annotation (@{ $self->get_sequence_set->{$seqAcc} }){
        #      last EV; 
				#		  $succeed++; 
        #    }
        #   }
        #}
			} elsif ($evObj->type eq "GENPROP")	{																		#if the type is GenProp
        if(defined($self->get_defs->{$evObj->accession})){
          # For properties a PARTIAL or YES result is considered success           
          if( $self->get_defs->{ $evObj->accession }->result eq 'YES' or 
                $self->get_defs->{ $evObj->accession}->result eq 'PARTIAL' ){
              $succeed++;
           }elsif($self->get_defs->{ $evObj->accession }->result eq 'UNTESTED'){
              $step->evaluated(0);  
#Todo - need to check this bit. Some times a step can have two evidences, so need to check this is okay.               
           }
        }
		  }
	  }
  }
	if ($succeed){
    $step->found(1);
	}
}

sub read_properties {
  my($self) = @_;
  
  
  #We can read genome_properties from a variety of files
    #During the option initailisation we should have 
    #been told if we have a file or a database.
    #If not, we are got to fail!
  if($self->gp_source eq 'file'){
    $self->_read_properties_from_file
  }elsif($self->gp_source eq 'db'){
    $self->_read_properties_from_db 
  }else{
    croak("No source for genome properties.");
  }
  #See if we have been told about an execution order for the GPs.
  #This is important as some GP rely in others.  Otherwise, we will
  #run iteratively. 
  $self->set_execution_order(); 
}



sub write_properties {
  my ($self) = @_;
  
  if($self->gp_out eq 'file'){
    $self->_write_properties_to_file
  }elsif($self->gp_out eq 'db'){
    $self->_write_properties_to_db 
  }else{
    croak("No source for genome properties.");
  }
}
=head1 set_execution_order

Title: 

=cut

sub set_execution_order {
  my ($self) = @_;

  if(!defined($self->{execution_order})){
    my $order;
    #If we have a db connection, use this
    #If we have an order file use that
    #Else, just use the sorted list of accessions.
    if($self->gp_source eq 'file' and $self->_order_file){
      $order = $self->_read_order_from_file;
    }elsif($self->gp_source eq 'db'){
      $order = $self->_read_order_from_db;
    }else{
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
  open(FH, '<', $self->_order_file) or croak("Failed to open order file:".$self->_order_file."\n");
  while(<FH>){
    chomp;
    push(@order, $_);
  }
  close(FH);

  
  return(\@order);

}


sub _gp_def_file {
  my ($self) = @_;
  #now construct the full path.
  return($self->{gpdir}.'/'.$self->{_prop_def});
}


sub _gp_step_file {
  my ($self) = @_;
  #now construct the full path.
  return($self->{gpdir}.'/'.$self->{_prop_step});
}

sub _gp_step_ev_file {
  my ($self) = @_;
  #now construct the full path.
  return($self->{gpdir}.'/'.$self->{_step_ev_link});
}


sub _write_properties_to_file {
  my ($self) = @_;

  #$self->_write_defs;
  #$self->_write_steps;  
  $self->_write_step_evidences;
}

sub _read_properties_from_file {
  my ($self) = @_;
  
  #See if the file is present, if it is, open it and read it.
  my $fh;
  if(-e $self->_gp_def_file){
    if(-s $self->_gp_def_file){
      open($fh, $self->_gp_def_file) or croak("Failed to open ".$self->gp_def_file."\n");
      $self->_parse_defs($fh);
      close($fh)
    }else{
      croak("The genome properties file has no size ".$self->_gp_def_file."\n");
    }
  }else{
    croak("The geneome properties file, ".$self->_gp_def_file." does not exist.\n");
  }
  
  if(-e $self->_gp_step_file){
    if(-s $self->_gp_step_file){
      open($fh, $self->_gp_step_file) or croak("Failed to open ".$self->gp_step_file."\n");
      $self->_parse_step($fh);
      close($fh)
    }else{
      croak("The genome properties file has no size ".$self->_gp_step_file."\n");
    }
  }else{
    croak("The geneome properties file, ".$self->_gp_step_file." does not exist.\n");
  }


  if(-e $self->_gp_step_ev_file){
    if(-s $self->_gp_step_ev_file){
      open($fh, $self->_gp_step_ev_file) or croak("Failed to open ".$self->gp_step_ev_file."\n");
      $self->_parse_evidence($fh);
      close($fh)
    }else{
      croak("The genome properties file has no size ".$self->_gp_step_ev_file."\n");
    }
  }else{
    croak("The geneome properties file, ".$self->_gp_step_ev_file." does not exist.\n");
  }

}

sub _parse_defs {
  my ($self, $fh) = @_;


  while( my $line = <$fh>){
    chomp($line);
    #splits up the prop def file lines by tab 				
    # Line looks like this:
    # 1       chorismate biosynthesis via shikimate   PATHWAY GenProp0001     1       2       SIMPLE
	  my @split_line = split(/\t/, $line); 
    
    #Need some QC here to check that we at least have the correct data
    if(scalar(@split_line) != 7){
      $self->croak("Error parsing line $line.  Go ".scalar(@split_line).", yet expected 7.\n");
    }


    my $gpd = GenomeProperties::Definition->new( {'accession' => $split_line[3],
                           'type'      => $split_line[2],
                           'name'      => $split_line[1],
                           'map'       => $split_line[0],
                           'public'    => $split_line[4],
                           'threshold' => $split_line[5],
                           'method'    => $split_line[6]} );
    $self->add_def($gpd);
  }
}

sub fromDESC {
  my ($self, $data ) = @_;
  my $gpd = GenomeProperties::Definition->new( {'accession' => $data->{AC},
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
  if($data->{REFS}){
    $gpd->refs($data->{REFS});
  }
  if($data->{DBREFS}){
    $gpd->dbrefs($data->{DBREFS});
  }
  $self->add_def($gpd);
  my $order = 0;
	foreach my $step (@{$data->{STEPS}}){
    $order++;
    my $stepObj = GenomeProperties::Step->new({ order        => $step->{SN},
                                             step_name    => $step->{ID},
                                             required     => $step->{RQ},
                                             in_rule      => 1,
                                             alter_name   => $step->{DN} });
    $gpd->add_step($stepObj);
    foreach my $ev (@{$step->{EVID}}){
      my $evObj;
      if($ev->{gp}){
        $evObj = GenomeProperties::StepEvidence->new( {
                                                      genome_property => $ev->{gp}
                                                     } );
      }else{
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
}

sub toDESC {
  my ($self, $path ) = @_;

  my $defs = $self->get_defs;
  p($defs);
  
  my $descfile;
  if ($path) {
    $descfile = $path . "/DESC";
  }
  else {
    $descfile = "DESC";
  }
  open( D, ">$descfile" )
    or die "Could not open $descfile file for writing to\n";
  $Text::Wrap::unexpand = 0;
  $Text::Wrap::columns = 76;
 

  while (my ($acc, $desc) = each %$defs) {
    p($acc);
    print D wrap( "AC  ", "AC  ", $desc->accession );
    print D "\n";
    print D wrap( "DE  ", "DE  ", $desc->name);
    print D "\n";
    print D wrap( "TP  ", "TP  ", $desc->type); 
    print D "\n";

    print D wrap( "AU  ", "AU  ", $desc->author);
    print D "\n";
    print D wrap( "TH  ", "TH  ", $desc->threshold);
    print D "\n";
    
    if(defined($desc->refs)){
      foreach my $ref ( @{ $desc->refs } ) {
        if ( $ref->{RC} ) {
          print D wrap( "RC   ", "RC   ", $ref->{RC} );
          print D "\n";
        }
        print D "RN  [" . $ref->{RN} . "]\n";
        print D "RM  " . $ref->{RM} . "\n";
        print D wrap( "RT  ", "RT  ", $ref->{RT} );
        print D "\n";
        print D wrap( "RA  ", "RA  ", $ref->{RA} );
        print D "\n";
        print D "RL  " . $ref->{RL} . "\n";
      }
    }
    if(defined($desc->dbrefs)){    
      foreach my $xref ( @{ $desc->dbrefs } ) {
        #Print out any comment
        if ( $xref->{db_comment} ) {
          print D wrap "DC  ", "DC  ", $xref->{db_comment};
          print D "\n";
        }
        if ( $xref->{other_params} ) {
          print D "DR  "
          . $xref->{db_id} . "; "
          . $xref->{db_link} . "; "
          . $xref->{other_params} . ";\n";
        } else {
          print D "DR  " . $xref->{db_id} . "; " . $xref->{db_link} . ";\n";
        }
      }
    }
    if(defined($desc->parents)){
      foreach my $parent (@{ $desc->parents}){
        print D "PN  $parent\n"; 
      }
    }
    print D wrap( "CC  ", "CC  ", $desc->comment);
    print D "\n";
    print D wrap( "**  ", "**  ", $desc->private);
    print D "\n";

    foreach my $step (@{ $desc->get_steps }){
      print D "--\n";
      print D "SN  ".$step->order."\n";
      print D "ID  ".$step->step_name."\n";
      print D "DN  ".$step->alter_name."\n" if(defined($step->alter_name));
      print D "RQ  ".$step->required."\n";
      foreach my $ev (@{ $step->get_evidence}){
        print D "EV  ".$ev->interpro."; ".$ev->accession."; ".$ev->type.";\n";
        if($ev->get_go){
          print D  "TG  ".$ev->get_go.";\n";
        }
      }
    }
    print D "//\n"    
  }
}


sub toDESCHack {
  my ($self, $path ) = @_;

  my $defs = $self->get_defs;
 
  my %comments; 
  open(C, '<', '/tmp/gp.clean.tsv') or die;
  while(<C>){
    chomp;
    my($prop, $comment, $private) = split(/\t/, $_);
    $comments{$prop}->{c} = $comment;
    $comments{$prop}->{p} = $private;

  }

  open(I, '<', '/Users/rdf/Projects/InterPro/GenomeProperties/projects/GenomeProperties/data/flatfiles/my_dumps/gp2interpro.txt') or die;
  my %interpro;
  while(<I>){
    chomp;
    my ($a, $b, $sig, $ipr) = split(/\t/, $_);
    $interpro{$sig} = $ipr;
  }
  close(I);
  
  open(I, '<', '/Users/rdf/Projects/InterPro/GenomeProperties/projects/GenomeProperties/data/flatfiles/my_dumps/sufficient_components.tsv') or die;
  my %sufficient;
  while(<I>){
    chomp;
    my ($gp, $sig, $status) = split(/\t/, $_);
    $sufficient{"$gp$sig"} = $status if($status and $status =~ /\S+/);
  }
  close(I);

  open(I, '<', '/Users/rdf/Projects/InterPro/GenomeProperties/projects/GenomeProperties/data/flatfiles/my_dumps/getGo.tsv') or die;
  my $go;
  while(<I>){
    chomp;
    my ($gp, $goacc, $step) = split(/\t/, $_);
    $go->{$gp}->{$step} = $goacc;
  }
  close(I);
 
 #GenProp0113     IUBMB: Corrin Biosynthesis (part 3)     http://www.chem.qmul.ac.uk/iubmb/enzyme/reaction/tetrapyr/corrin3.html
  open(I, '<', '/Users/rdf/Projects/InterPro/GenomeProperties/projects/GenomeProperties/data/flatfiles/my_dumps/iubmb.tsv') or die;
  my $dbrefs;
  while(<I>){
    chomp;
    my ($gp, $dc, $p1, $p2) = $_ =~ /(GenProp\d+)\tIUBMB\: (.*?)\thttp.*?(\w+)\/(\w+)\.html/;
    push(@{$dbrefs->{$gp}}, { db_comment => $dc, db_id => 'IUBMB', db_link => $p1, other_params => $p2 });
  }
  close(I);
 #GenProp0001     Phenylalanine, Tyrosine and Tryptophan Biosynthesis     http://www.genome.ad.jp/kegg/pathway/map/map00400.html
  open(I, '<', '/Users/rdf/Projects/InterPro/GenomeProperties/projects/GenomeProperties/data/flatfiles/my_dumps/kegg2.tsv') or die;
  while(<I>){
    chomp;
    my ($gp, $dc, $p1) = $_ =~ /(GenProp\d+)\t(.*?)\thttp.*?(map\d+)/;
    if($gp){
      push(@{$dbrefs->{$gp}}, { db_comment => $dc, db_id => 'KEGG', db_link => $p1});
    }else{
      warn "$_\n";
    }
  }
  close(I);
 
  open(I, '<', '/Users/rdf/Projects/InterPro/GenomeProperties/projects/GenomeProperties/data/flatfiles/my_dumps/metacycall') or die;
  while(<I>){
    chomp;
    my ($gp, $dc, $p1) = $_ =~ /(GenProp\d+)\t(.*?)\thttp.*?object=(.*)/;
    if($gp){
      push(@{$dbrefs->{$gp}}, { db_comment => $dc, db_id => 'MetaCyc', db_link => $p1});
    }else{
      warn "$_\n";
    }
  } 
  
  open(I, '<', '/Users/rdf/Projects/InterPro/GenomeProperties/projects/GenomeProperties/data/flatfiles/my_dumps/Wikipedia') or die;
  while(<I>){
    chomp;
    my ($gp, $link ) = $_ =~ /(GenProp\d+)\tWikipedia\:(\S+)/;
    if($gp){
      push(@{$dbrefs->{$gp}}, { db_id => 'Wikipedia', db_link => $link});
    }else{
      warn "$_\n";
    }
  } 

  my $refs;
  my %refCount;
  open(I, '<', '/Users/rdf/Projects/InterPro/GenomeProperties/projects/GenomeProperties/data/flatfiles/my_dumps/gp.lit_refs') or die;
  while(<I>){
    chomp;
    my ($gp, $pmid ) = $_ =~ /(GenProp\d+)\tPMID\:(\d+)/;
    if($gp){

    my $url = "http://www.ebi.ac.uk/europepmc/webservices/rest/search?format=json&query=ext_id:$pmid";
    my $content = get($url);

    my $ref = from_json($content);
      foreach my $refObj (@{$ref->{resultList}->{result}}){
        next unless $refObj->{pmid} == $pmid;
        $refObj->{authorString} =~ s/(\.)$//;
        $refCount{$gp} = 0 if(!$refCount{$gp});
        $refCount{$gp}++;
        push(@{$refs->{$gp}}, { RN => $refCount{$gp}, 
                              RM => $pmid,
                              RT => $refObj->{title},
                              RA => $refObj->{authorString}.";",
                              RL => $refObj->{journalTitle}.". ".$refObj->{pubYear}.";".$refObj->{journalVolume}.":".$refObj->{pageInfo}."."
                              });
        last;
      }
    }else{
      warn "$_\n";
    }
  } 


  foreach my $acc (sort{ $a cmp $b } keys %$defs) {
    my $descfile;
    if ($path) {
      $descfile = $path . "/DESC";
    }
    else {
      $descfile = "DESC";
    }
    if(!-d "all/".$acc){
      mkdir("all/$acc");
    }
  open( D, ">all/$acc/$descfile" )
    or die "Could not open $descfile file for writing to\n";
  $Text::Wrap::unexpand = 0;
  $Text::Wrap::columns = 76;
 

    my $desc = $defs->{$acc};
    print D wrap( "AC  ", "AC  ", $desc->accession );
    print D "\n";
    print D wrap( "DE  ", "DE  ", $desc->name);
    print D "\n";
    print D wrap( "TP  ", "TP  ", $desc->type); 
    print D "\n";

    print D wrap( "AU  ", "AU  ", "Haft D");

    print D "\n";
    print D wrap( "TH  ", "TH  ", $desc->threshold);
    print D "\n";
    
    if($refs->{$desc->accession}){
      $desc->refs($refs->{$desc->accession});
    }
    if(defined($desc->refs)){
      foreach my $ref ( @{ $desc->refs } ) {
        if ( $ref->{RC} ) {
          print D wrap( "RC   ", "RC   ", $ref->{RC} );
          print D "\n";
        }
        print D "RN  [" . $ref->{RN} . "]\n";
        print D "RM  " . $ref->{RM} . "\n";
        print D wrap( "RT  ", "RT  ", $ref->{RT} );
        print D "\n";
        print D wrap( "RA  ", "RA  ", $ref->{RA} );
        print D "\n";
        print D "RL  " . $ref->{RL} . "\n";
      }
    }
    if($dbrefs->{$desc->accession}){
      $desc->dbrefs($dbrefs->{$desc->accession});
    }
    if(defined($desc->dbrefs)){    
      foreach my $xref ( @{ $desc->dbrefs } ) {
        #Print out any comment
        if ( $xref->{db_comment} ) {
          print D wrap "DC  ", "DC  ", $xref->{db_comment};
          print D "\n";
        }
        if ( $xref->{other_params} ) {
          print D "DR  "
          . $xref->{db_id} . "; "
          . $xref->{db_link} . "; "
          . $xref->{other_params} . ";\n";
        } else {
          print D "DR  " . $xref->{db_id} . "; " . $xref->{db_link} . ";\n";
        }
      }
    }
    if(defined($desc->parents)){
      foreach my $parent (@{ $desc->parents}){
        print D "PN  $parent\n"; 
      }
    }


    
    $desc->{comment} = $comments{$desc->accession}->{c};
    $desc->{private} = $comments{$desc->accession}->{p} if ($comments{$desc->accession}->{p} =~ /\S+/);
    
    if($desc->comment and $desc->comment =~ /\S+/){
      print D wrap( "CC  ", "CC  ", $desc->comment);
      print D "\n";
    }

    if($desc->private and $desc->private =~ /\S+/){
      print D wrap( "**  ", "**  ", $desc->private);
      print D "\n" 
    }
    
    foreach my $step (sort{ $a->order cmp $b->order} @{ $desc->get_steps }){
      print D "--\n";
      print D "SN  ".$step->order."\n";
      print D "ID  ".$step->step_name."\n";
      print D "DN  ".$step->alter_name."\n" if(defined($step->alter_name) and $step->alter_name ne  'NULL' and $step->alter_name ne 'DEFER');
      print D "RQ  ".$step->required."\n";
      foreach my $ev (@{ $step->get_evidence}){
        if($interpro{ $ev->accession }){
          $ev->interpro($interpro{ $ev->accession });
          $ev->type('wibble');
          print D "EV  ".$interpro{$ev->accession}."; ".$ev->accession.";";
          if($sufficient{$desc->accession.$ev->accession}){
            print D " sufficient;";
          }
          print D "\n";
        }elsif( $ev->accession =~ /GenProp/){
          print D "EV  ".$ev->accession.";\n";

        }else{
          #warn $ev->accession ." not found in mapping\n" if($ev->accession =~ /PF|TIGR/);
          print D "EV  IPRXXXX; ".$ev->accession.";";
          if($sufficient{$desc->accession.$ev->accession}){
            print D " sufficient;";
          }
          print D "\n";

        }
        #print D "EV  ".$ev->interpro."; ".$ev->accession."; ".$ev->type.";\n";
        if(defined($go->{$desc->accession}->{$ev->get_go})){
          print D  "TG  ".$go->{$desc->accession}->{$ev->get_go}.";\n";
        }
      }
    }
    print D "//\n"    
  }
}


sub _write_defs { 
  my ($self, $fh) = @_;
  
  foreach my $gp ( keys %{ $self->get_defs }){
    my $def = $self->get_def($gp);
    my $line = join("\t", $def->map, $def->name, $def->type, $def->accession, $def->public, $def->threshold, $def->method);
    print "$line\n";
  }
  
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

sub get_defs {
  my ($self) = @_;
  return($self->{properties});
}

sub get_def {
  my ($self, $acc) = @_;
  
  if(!$acc){
    carp("No accession passed in.\n"); 
  }
  
  if(!defined($self->{properties}->{$acc})){
    carp("No property found for this accession ($acc)\n");  
    return 0;
  }else{
    return($self->{properties}->{$acc});
  }
}


sub _parse_step {
  my($self, $fh) = @_;
  while (my $line = <$fh>){																			#go through step table line by line
    #76      1       5       shikimate kinase        1       1       shikimate kinase (EC  2.7.1.71)
    chomp($line); 
	  
    my @split_line = split(/\t/, $line);															#split up the line of step table by tab
    if(scalar(@split_line) != 7){
      croak("Unexpected number of elements in line $line, of step file\n");
    }

    #Now look at the file and build up.....
    
    if ($split_line[0] =~ /^\d/){		#is 2 number in each line of step table = step_link??????
			my $step = GenomeProperties::Step->new({ int_step_id  => $split_line[0],
                                               def_id       => $split_line[1],
                                               order        => $split_line[2],
                                               step_name    => $split_line[3],
                                               required     => $split_line[4],
                                               in_rule      => $split_line[5],
                                               alter_name   => $split_line[6]
                                               });
      $self->add_step($step);
		}
  }
}

sub _write_steps{
  my ($self) = @_;

  foreach my $gp ( keys %{ $self->get_defs }){
    my $def = $self->get_def($gp);
    next if(!defined($def));
    foreach my $step (sort {$a->order <=> $b->order}@{$def->get_steps}){
      my $line = join("\t", $step->int_step_id,
                            $step->def_id, 
                            $step->order, 
                            $step->step_name, 
                            $step->required, 
                            $step->in_rule,
                            $step->alter_name );
      print "$line\n";
    }
  }

}


sub add_step {
  my ( $self, $step ) = @_;
    
  #Look up the GP def that we need to attach this step to.
  my $acc = $self->{_defmap}->{$step->def_id};
  $step->def_acc($acc) if(!$step->def_acc);
  my $def = $self->{properties}->{$acc};

  $def->add_step($step);
  $self->{_stepmap}->{$step->int_step_id}=$acc;
}



sub _parse_evidence{
  my ($self, $fh ) = @_;



  while (my $line = <$fh>) {																			#go through it line by line
    chomp($line);
    my @split_line = split(/\t/, $line);															#split the line up by tabs
    my $ev = GenomeProperties::StepEvidence->new( { step_ev_id => $split_line[0],
                                                    step       => $split_line[1],
                                                    accession  => $split_line[2],
                                                    method       => $split_line[3],
                                                    get_go     => $split_line[4],
                                                      } );
      
    $self->add_step_evidence($ev);
  }
}

sub _write_step_evidences {
  my ( $self ) = @_;
  

  foreach my $gp ( keys %{ $self->get_defs }){
    my $def = $self->get_def($gp);
    next if(!defined($def));
    foreach my $step (sort {$a->order <=> $b->order}@{$def->get_steps}){
      foreach my $ev (@{$step->get_evidence}){
        my $line = join( "\t", $ev->step_ev_id, $ev->step, $ev->accession, $ev->type, $ev->get_go);  
        print "$line\n";
      }
    }  
  }


}


sub add_step_evidence {
  my ($self, $ev) = @_;
    
  my $s = undef;
  my $acc = $self->{_stepmap}->{$ev->{step}};
  my $def = $self->{properties}->{$acc};
  foreach my $step ( @{$def->get_steps} ){
    if($step->int_step_id == $ev->{step}){
      $step->add_evidence($ev);
      last;
    }
  }
  
}


sub gp_source {
  my ($self) = @_;

  my $s = '';
  if($self->{db}){
    $s = 'db'
  }else{
    $s = 'file';
  }

  return($s);
}

sub gp_out {
  my ($self) = @_;

  my $s = '';
  if($self->{db_out}){
    $s = 'db'
  }else{
    $s = 'file';
  }

  return($s);
}
1;
