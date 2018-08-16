package GenomePropertiesIO;

use strict;
use warnings;
use Carp;
use Clone 'clone';
use JSON;
use Try::Tiny;
use DDP;
use LWP::UserAgent;

use GenomeProperties;

my %TYPES = ( METAPATH => 1,
              SYSTEM   => 1,
              GUILD    => 1,
              CATEGORY => 1,
              PATHWAY  => 1,
              SUMMARY  => 1,
              COMPLEX  => 1,
              #ROOT     => 1
              );

my @ORDER = qw(PATHWAY METAPATH SYSTEM GUILD CATEGORY);

sub validateGP {
  my($gp, $options) = @_;
    
  my $globalError = 0;
  
  #Read the DESC
	DESC:
  foreach my $dir (sort @{$options->{dirs}}){
    #TODO: put status check in here
    next DESC if(defined($options->{status}) and ! _checkStatus($dir, $options));

    if(!-d $dir){
      print STDERR "$dir does not exist\n";
      $globalError = 1;
      next DESC;
    }
    eval{
      parseDESC("$dir/DESC", $gp, $options);
    };
    if($@){
      print STDERR "$dir: does not pass check $@\n";
      open(E, ">", "$dir/error");
      print E "Error parsing DESC:\n $@\n";
      close(E);
      $globalError = 1;
    }
  }


  #Does it have any steps that we should have a sequence for testing
  if($gp->get_defs){
     my @gpsToCheck = sort keys %{$gp->get_defs};
     
     foreach my $prop_acc (@gpsToCheck){
      my $errors = 0;   
      my $errorMsg = '';
      #We may not have seen this before if recusion is on
      if(!$gp->get_defs->{$prop_acc} ){ 
        if(defined($options->{status}) and ! _checkStatus($prop_acc, $options)){
          warn "Skipping $prop_acc due to status\n";
          next;
        }
        eval{
          parseDESC("$prop_acc/DESC", $gp, $options);
        };
        if($@){
          print STDERR "$prop_acc: does not pass check $@\n";
          open(E, ">", "$prop_acc/error");
          print E "Error parsing DESC:\n $@\n";
          $errors = 1;
          $errorMsg .= "Error parsing DESC, $@\n";
        }
      }
      
      
      my $prop = $gp->get_def($prop_acc);
      if(!$prop ){
        die "Failed to establish property for $prop_acc\n";
      }
     
      #Check essential fields
      _checkEssentials($prop, \$errors, \$errorMsg);

      #Check threshold is less than number 
      #of steps
      _checkThreshold($prop, \$errors, \$errorMsg);

      #Check type vs steps
      _checkTypeAgainstStep($prop, \$errors, \$errorMsg);    
      
      #Check steps against IPR info etc.
      if($options->{interpro}){
        _checkSteps($prop, $options, \$errors, \$errorMsg);    
      }
      
      if($options->{checkgoterms}){
        _checkStepsGO($prop, $options, \$errors, \$errorMsg);
      }

      #Check FASTA
      _checkFASTA($prop, \$errors, \$errorMsg, $options, \@gpsToCheck);    
      
      
      if($errors){
        print "$prop_acc: does not pass check\n";
        open(E, ">", "$prop_acc/error");
        print E $errorMsg;
        close(E);
        print $errorMsg;
        $globalError = 1;
      }else{
        unlink("$prop_acc/error") if(-e "$prop_acc/error");
        print "$prop_acc: passes check\n";
      }
    }
  }
  if($globalError){
    warn "One or more of the GPs listed has an error, see log above and GP/error file.\n";
    return 0;
  }else{
    return 1;
  }
}

sub checkHierarchy {
  my ($gp, $options) = @_;
  
  
  if($gp->get_defs){
    my %propSet;
    my @gpsToCheck = sort keys %{$gp->get_defs};
    foreach my $prop_acc (@gpsToCheck){
      $propSet{$prop_acc} = 0;
    }
    
    #Now go and get the evidences out of the set.
    foreach my $prop_acc (sort keys %propSet){
      my $prop = $gp->get_def($prop_acc);
      STEP:
      foreach my $step (@{ $prop->get_steps }){
        foreach my $evidence (@{$step->get_evidence}){
          if($evidence->gp){
            if( exists( $propSet{$evidence->gp} ) ){
              $propSet{$evidence->gp} = 1;
            }else{
              warn $evidence->gp." is refered to by $prop_acc, but is not currently in the set\n";
            }
          }
        }
      }
    }

    #Now make sure that all GPs are connected.
    #GenProp0065 is root and special
    foreach my $prop_acc (sort keys %propSet){

      if($propSet{$prop_acc} == 0){
        if($prop_acc ne "GenProp0065"){
          warn "$prop_acc is disconnected in the hierarchy\n"; 
        }
      }
    }
  }else{
    die "Should have pre-populated the GenomeProperities object with definitions\n";
  }
  return 1;

}


sub JSONHierarchy {
  my ($gp, $options) = @_;

  my $rootGP = "GenProp0065";
  my $tree;

  my $prop = $gp->get_def($rootGP);
  $tree->{id} = $prop->accession;
  $tree->{name} = $prop->name;
  $tree->{children} = [];

  _buildHierarchy($gp, $prop, $tree);
  my $treeString =  to_json( $tree, { ascii => 1 } ); 
  return($treeString);
}

sub _buildHierarchy {
  my ($gp, $prop, $tree) = @_;
   
  foreach my $step (@{ $prop->get_steps }){
    foreach my $evidence (@{$step->get_evidence}){
      if($evidence->gp){
        my $childGp = $gp->get_def($evidence->gp);
        my $child = { id => $childGp->accession, name => $childGp->name, children => [] };
        push(@{$tree->{ children }}, $child);
        _buildHierarchy($gp, $childGp, $child);
      }
    }
  }

}


sub _checkFASTA {
  my ($prop, $errors, $errorMsg, $options, $gpToCheckAR) = @_;

  my $prop_acc = $prop->accession;
  my @gpsToCheck;
  #No steps, then we need to 
  if(scalar(@{$prop->get_steps})){
    my $seqs;
    if( -e "$prop_acc/FASTA"){
      eval{
        $seqs = parseGpFASTA($prop_acc);
      };
      if($@){
          $$errorMsg .= "Error parsing Fasta: $@\n";
          $$errors++;
      }
    }
    #We have parsed the file, now cross reference
    STEP:
    foreach my $step (@{ $prop->get_steps }){
      foreach my $evidence (@{$step->get_evidence}){
        if($evidence->interpro){
          if(!defined($seqs->{$step->order})){
              $$errorMsg .= "Did not find a sequence for ".$step->order." in $prop_acc\n";
              $$errors++;
          }
          next STEP;
        }elsif($evidence->gp){
          my %all = map{ $_ => 1 } @$gpToCheckAR;
          if($options->{recursive}){
            if(!$all{$evidence->gp}){
              push(@$gpToCheckAR, $evidence->gp);
            }
          }else{
            if(!defined($all{$evidence->gp})){
              if($options->{verbose}){
                warn("Reference to ".$evidence->gp." found, but not checked validity.\n");  
              }
            }
          }
        }else{
          die "Unknown evidence type\n";
        }
      }
    }
  }
}

sub _checkThreshold {
  my ( $prop, $error, $error_msg) = @_;
   
  my $noStep = scalar(@{$prop->get_steps});
  if($noStep < $prop->threshold){
    $$error++;
    $$error_msg .= "Threshold of greater than the number of steps\n";
  }
  return;
}


sub _checkEssentials {
  my ($prop, $errors, $errorMsg) = @_;

  #DE, TP, AU, TH are all required
  if(!$prop->type or $prop->type !~ /\S+/){
    $$errors++;
    $$errorMsg .= "No property type set for ".$prop->accession."\n";
  }

  #if($prop->type eq 'ROOT' or $prop->type eq 'CATEGORY' or $prop->type eq 'SUMMARY'){
  
  #For each step SN, ID, RQ are all ressential.
  #die;

}

sub _checkTypeAgainstStep {
  my ($prop, $errors, $errorMsg) = @_;

  my $noSteps = scalar(@{$prop->get_steps});
  # Thes should have all steps as GP

  if( $prop->type eq 'CATEGORY' ){
    
    my $gps = 0;
    STEP:
    foreach my $step (@{ $prop->get_steps }){
      foreach my $evidence (@{$step->get_evidence}){
        if($evidence->gp){
          $gps++
        }
      }
    }   
    if($noSteps !=  $gps ){
  if($prop->type eq 'ROOT' or $prop->type eq 'SUMMARY'){
    if($noSteps > 0){
      $$errors++;
      $$errorMsg .= "Got type ".$prop->type." but this should have all Genome Property steps\n";
    }
  }
}
}
  if($prop->type eq 'GUILD' or $prop->type eq 'SYSTEM' or $prop->type eq 'CATEGORY' 
        or $prop->type eq 'PATHWAY' or $prop->type eq 'METAPATH'){
    if($noSteps == 0){
      $$errors++;
      $$errorMsg .= "Got type ".$prop->type." but this should have steps\n";

    }
  }
  
  if($prop->type eq 'METAPATH'){
    #Not all evidence should be interpro.
    my $gps = 0;
    STEP:
    foreach my $step (@{ $prop->get_steps }){
      foreach my $evidence (@{$step->get_evidence}){
        if($evidence->gp){
          $gps++
        }
      }
    }
    if($gps == 0){
      $$errors++;
      $$errorMsg .= "Got no GenProps as evidence in METAPATH\n";
    }
  }
}


sub _checkSteps{
  my ($prop, $options, $errors, $errorMsg) = @_;
  
  if($prop->type eq 'GUILD' or $prop->type eq 'SYSTEM' or 
      $prop->type eq 'PATHWAY' or $prop->type eq 'METAPATH'){
    STEP:
    foreach my $step (@{ $prop->get_steps }){
      foreach my $evidence (@{$step->get_evidence}){
        if($evidence->interpro){
          if(!defined($options->{interpro}->{ $evidence->interpro })){
            $$errors++;
            $$errorMsg .= "InterPro accession, ".$evidence->interpro.", is not a valid accession\n";
          }else{
            #Okay, now check the accession/siganture evidence is valid
            if(!defined($options->{interpro}->{ $evidence->interpro }->{signatures}->{$evidence->accession})){
              $$errors++;
              $$errorMsg .= "Member database accession, ".$evidence->accession.", is not assocaited with ".$evidence->interpro."\n";
            }
          }
        }
      }
    }
  }   
}

sub _checkStepsGO{
  my ($prop, $options, $errors, $errorMsg) = @_;
  
    STEP:
    foreach my $step (@{ $prop->get_steps }){
      foreach my $evidence (@{$step->get_evidence}){
        if($evidence->get_go){
          foreach my $go (@{$evidence->get_go}){
            _checkGO($go, $options, $errors, $errorMsg); 
          }
        }
      }
    }
}



sub _checkGO {
  my ($go, $options, $errors, $errorMsg) = @_;
  if(defined($options->{goterms}->{$go})){
    #All is good;
    return;
  }else{
		#These three lines should probably be done once.
   	my $ua = LWP::UserAgent->new;
 		$ua->timeout(10);
 		$ua->env_proxy;
    $ua->ssl_opts( 'verify_hostname' => 0 );
 		my $response = $ua->get("https://www.ebi.ac.uk/ols/api/ontologies/go/terms?obo_id=$go"); 

		if ($response->is_success) {
  		$options->{goterms}->{$go}++
 		} else {
        
     	$$errors++;
			$$errorMsg .= "Failed to find the GO term $go\n";
      # $response->status_line;
      $$errorMsg .= $response->status_line;
 		} 
  }
}


sub parseGpFASTA {
  my ($dir) = @_;
  
  open(F, "<", "$dir/FASTA") or die "Could not open $dir/FASTA\n";
  my $currentStep = 0;
  my $seqs = {};
  while(<F>){
    if(/^>\S+\s+\(Step num: (\S+)\)/){
      $currentStep= $1;
      $seqs->{$currentStep} = $_;
    }elsif(!/^>/){
      $seqs->{$currentStep} .= $_;
    }else{
      die "Failed to parse FASTA for $dir, line |$_|\n"; 
    }
  }
  close(F);
  return($seqs);

}


sub parseFlatfile {
  my ($gp, $file) = @_;
  
  open(F, "<", $file) or die "Could not open $file\n";
  $/ = "//";
  while(<F>){
    $/ = "\n";
    my @file = split(/\n/, $_);
      
    shift(@file) if(defined($file[0]) and $file[0] eq "");
    if(scalar(@file)){
      parseDESC(\@file, $gp, {});
    }
    $/ = "//";
  }
  close(F);
  $/ = "\n";
  
}

sub parseDESC {
  my ( $file, $gp, $options ) = @_;

  my @file;
  if ( ref($file) eq "GLOB" ) {
    @file = <$file>;
  }elsif(ref($file) eq "ARRAY"){
    @file = @$file;
  }else {
    open( my $fh, "$file" ) or die "Could not open $file:[$!]\n";
    @file = <$fh>;
    close($file);
  }

  my %params;
  my $expLen = 80;

  my $refTags = {
    RC => {
      RC => 1,
      RN => 1
    },
    RN => { RM => 1 },
    RM => { RT => 1 },
    RT => {
      RT => 1,
      RA => 1
    },
    RA => {
      RA => 1,
      RL => 1
    },
    RL => { RL => 1 },
  };

  for ( my $i = 0 ; $i <= $#file ; $i++ ) {
    
    my $l = $file[$i];
    chomp($l);
    if ( length($l) > $expLen ) {
      #DE|DN|EV these are allowed to exceed length
      if($l !~ /^(DE|DN|EV)/){
        die( "\nGot a DESC line that was longer the $expLen, $file[$i]\n\n"
          . "-" x 80
          . "\n" );
      }
    }

    if ( $file[$i] =~ /^(AC|DE|AU|TP|TH|)\s{2}(.*)$/ ) {
      if(exists($params{$1})){
        my $msg = "\n";; 
        $msg .= $params{AC}.": " if($params{AC}); 
        $msg .= "Found more than one line containing the $1 tag.\n\n"
         . "-" x 80
                . "\n"; 
        warn($msg);
      }
      $params{$1} = $2;
      #TODO - make sure type matechs oe of the recognised types.
      if($1 eq "TP"){
        if(!$TYPES{$2}){
          die "Incorrect TP |$2| field in DESC\n";
        }
      }
      next;
    }
    elsif ( $file[$i] =~ /^\*\*\s{2}(.*)$/ ) {
      $params{private} .= " " if ( $params{private} );
      $params{private} .= $1;
    }
    elsif ( $file[$i] =~ /^PN\s{2}(GenProp\d{4})$/ ) {
      my $prop = $1;
      push(@{$params{"PARENT"}}, $prop);
    }
    elsif ( $file[$i] =~ /^CC\s{2}(.*)$/ ) {
      my $cc = $1;
      while ( $cc =~ /(\w+):(\S+)/g ) {
        my $db  = $1;
        my $acc = $2;
      }
      if ( $params{CC} ) {
        $params{CC} .= " ";
      }
      $params{CC} .= $cc;
      next;
    }
    elsif ( $file[$i] =~ /^R(N|C)\s{2}/ ) {
      my $ref;
    REFLINE:
      foreach ( my $j = $i ; $j <= $#file ; $j++ ) {
        if ( $file[$j] =~ /^(\w{2})\s{2}(.*)/ ) {
          my $thisTag = $1;
          if ( $ref->{$1} ) {
            $ref->{$1} .= " $2";
          }
          else {
            $ref->{$1} = $2;
          }
          if ( $j == $#file ) {
            $i = $j;
            last REFLINE;
          }
          my ($nextTag) = $file[ $j + 1 ] =~ /^(\S{2})/;

          if(!defined($nextTag)){
            die "Bad reference format\n";
          }
          #Now lets check that the next field is allowed
          if ( $refTags->{$thisTag}->{$nextTag} ) {
            next REFLINE;
          }
          elsif (
            (
              !$refTags->{$nextTag}
              or ( $nextTag eq "RN" or $nextTag eq "RC" )
            )
            and ( $thisTag eq "RL" )
            )
          {
            $i = $j;
            last REFLINE;
          }
          else {
            confess("Bad references fromat. Got $thisTag then $nextTag ");
          }
        }
      }
      $ref->{RN} =~ s/\[|\]//g;
      unless(exists($ref->{RN}) and $ref->{RN} =~ /^\d+$/){
        confess("Reference number should be defined and numeric\n");  
      }
      if(exists($ref->{RM})){
        unless( $ref->{RM} =~ /^\d+$/){
          confess("Reference medline should be numeric, got ".$ref->{RM}."\n");  
        }
      }
      push( @{ $params{REFS} }, $ref );
    }
    elsif ( $file[$i] =~ /^D\w\s{2}/ ) {
      for ( ; $i <= $#file ; $i++ ) {
        my $com;
        for ( ; $i <= $#file ; $i++ ) {
          if ( $file[$i] =~ /^DC\s{2}(.*)/ ) {
            $com .= " " if ($com);
            $com .= $1;
          }
          else {
            last;
          }
        }

        if ( !$file[$i] ) {
          confess("Found a orphan DT line\n");
        }

        if ( $file[$i] =~ /^DR  KEGG;\s/ ) {
          if ( $file[$i] !~ /^DR  (KEGG);\s+(\S+);$/ ) {
            confess("Bad KEGG DB reference [$file[$i]]\n");
          }
          push( @{ $params{DBREFS} }, { db_id => $1, db_link => $2 } );
        }
        elsif ( $file[$i] =~ /^DR  EcoCyc;\s/ ) {
          if ( $file[$i] !~ /^DR  (EcoCyc);\s+(\S+);$/ ) {
            confess("Bad EcoCyc reference [$file[$i]]\n");
          }
          push( @{ $params{DBREFS} }, { db_id => $1, db_link => $2 } );
        }
        elsif ( $file[$i] =~ /^DR  MetaCyc;\s/ ) {
          if ( $file[$i] !~ /^DR  (MetaCyc);\s+(\S+);$/ ) {
            confess("Bad EcoCyc reference [$file[$i]]\n");
          }
          push( @{ $params{DBREFS} }, { db_id => $1, db_link => $2 } );
        }
        elsif ( $file[$i] =~ /^DR  IUBMB/ ) {
          if ( $file[$i] !~ /^DR  (IUBMB);\s(\S+);\s(\S+);$/ ) {
            confess("Bad IUBMB DB reference [$file[$i]]\n");
          }
          push( @{ $params{DBREFS} }, { db_id => $1, db_link => $2, other_params => $3 } );
        }
        elsif ( $file[$i] =~ /^DR  (URL);\s+(\S+);$/ ) {
          print STDERR "Please check the URL $2\n";
          push( @{ $params{DBREFS} }, { db_id => $1, db_link => $2 } );
        }
        elsif ( $file[$i] =~ /^DR  (Complex Portal);\s+(CPX-\S+);$/ ) {
          push( @{ $params{DBREFS} }, { db_id => $1, db_link => $2 } );
        }
        elsif ( $file[$i] =~ /^DR  (PDBe);\s+(\S{4});$/ ) {
          push( @{ $params{DBREFS} }, { db_id => $1, db_link => $2 } );
        }
        elsif ( $file[$i] =~ /^DR/ ) {
          confess( "Bad reference line: unknown database [$file[$i]].\n"
              . "This may be fine, but we need to know the URL of the xref."
              . "Talk to someone who knows about these things!\n" );
        }
        else {

          #We are now on to no DR lines, break out and go back on position
          $i--;
          last;
        }
        if ($com) {
          $params{DBREFS}->[ $#{ $params{DBREFS} } ]->{db_comment} = $com;
        }
      }
    }
    elsif($file[$i] =~ /^--$/){
      $i++;
      my $steps = parseSteps(\@file, \$i, $options);
      $params{STEPS} = $steps;
    }elsif($file[$i] =~ /^\/\//){
      last; 
    } else {
      chomp( $file[$i] );
      my $msg = "Failed to parse the DESC line [$i] (enclosed by |):|$file[$i]|\n\n"
        . "-" x 80 . "\n";

      #croak($msg);
      die $msg;

#confess("Failed to parse the DESC line (enclosed by |):|$file[$i]|\n\n". "-" x 80 ."\n");
    }
  }
  $gp->fromDESC(\%params);
  #End of uber for loop
}


sub parseSteps {
  my($file, $i, $options) = @_;
  my $expLen=80;
  my @steps;
  my %step;
  for (  ; $$i <scalar(@{$file}) ; $$i++ ) {
      
    my $l = $file->[$$i];
    chomp($l);
    if ( length($l) > $expLen ) {
      warn( "\nGot a DESC line that was longer the $expLen, $l\n\n"
          . "-" x 80
          . "\n" ) if ($options->{verbose});
    }

    if ( $l =~ /^(SN|ID|DN|EC|RQ)\s{2}(.*)$/ ) {
      if(exists($step{$1})){
        confess("\nFound more than one line containing the $1 tag\n\n"
         . "-" x 80
                . "\n" );  
      }
      $step{$1} = $2;
      next;
    }elsif($l =~ /^EV\s{2}(IPR\d{6});\s(\S+);\s(\S+);$/){
        my $ipr = $1;
        my $sig = $2;
        my $suf = $3;
        my $nl = $file->[$$i + 1];
        my $go = [];
        while($nl =~ /^TG\s{2}(GO\:\d+)/){
          push(@$go, $1);
          $$i++;
          $nl = $file->[$$i + 1];
        }
        push(@{$step{EVID}}, { ipr => $ipr, sig => $sig, sc => $suf, go => $go });
    }elsif($l =~ /^EV\s{2}(IPR\d{6});\s(\S+);$/){
        my $ipr = $1;
        my $sig = $2;
        my $nl = $file->[$$i + 1];
        my $go = [];
        while($nl =~ /^TG\s{2}(GO\:\d+);$/){
          push(@$go, $1);
          $$i++;
          $nl = $file->[$$i + 1];
        }
        push(@{$step{EVID}}, { ipr => $ipr, sig => $sig, go => $go });

    }elsif($l =~ /^EV\s{2}(GenProp\d{4});$/){
        my $gp = $1;
        my $nl = $file->[$$i + 1];
        my $go = [];
        while($nl =~ /^TG\s{2}(GO\:\d+);$/){
          push(@$go, $1);
          $$i++;
          $nl = $file->[$$i + 1];
        }
        push(@{$step{EVID}}, { gp => $gp, go => $go });
    }elsif($l =~ /^--$/){  
      push(@steps, clone(\%step));
      %step = ();
    }elsif($l =~ /\/\//){
      push(@steps, clone(\%step));
      last;
    }else {
      my $msg = "Failed to parse the DESC line (enclosed by |):|$l|\n\n"
        . "-" x 80 . "\n";

      #croak($msg);
      die $msg;

#confess("Failed to parse the DESC line (enclosed by |):|$file[$i]|\n\n". "-" x 80 ."\n");
    }
  }
  
  return(\@steps);
}

sub _checkStatus {
  my($dir, $options) = @_;
  
  my $evaluate = 0;
  my($public, $checked);
	if(-e("$dir/status")){
		if(defined($options->{status})){
		 	open(S, "<", "$dir/status") or die "Could not open $dir/status file:[$!]\n";
			while(<S>){
				if(/^checked:\s+(\d)/){
					$checked=$1;;
				}elsif(/^public:\s+(\d)/){
					$public= $1;
				}
			}
      close(S);			
		  if($options->{recursive} and $options->{verbose}){
        print "$dir, public=$public, checked=$checked\n";
      }
      if($options->{status} =~ /public/ and $public != 1){
					return $evaluate;
			}

		 	if($options->{status} =~ /checked/ and $checked != 1){
			  return $evaluate;
			}
		}
	}else{
		if(defined($options->{status})){
			warn "$dir has no status file, yet a status check is required. Skipping\n";
      return $evaluate;
		}
	}
  $evaluate = 1;

  return $evaluate;
}


sub stats {
  my($gp, $options, $outdir) = @_;
    
  my $globalError = 0;
  
  #Read the DESC
	DESC:
  foreach my $dir (sort @{$options->{dirs}}){
    #TODO: put status check in here
    next DESC if(defined($options->{status}) and ! _checkStatus($dir, $options));
    #print STDERR "$dir\n";  
    eval{
      parseDESC("$dir/DESC", $gp, $options);
    };
    if($@){
      print STDERR "$dir: does not pass check $@\n";
      open(E, ">", "$dir/error");
      print E "Error parsing DESC:\n $@\n";
      close(E);
      $globalError = 1;
    }
  }

  my $stats;
  #Does it have any steps that we should have a sequence for testing
  if($gp->get_defs){
     my @gps = sort keys %{$gp->get_defs};
     
     foreach my $prop_acc (@gps){
        my $prop = $gp->get_def($prop_acc);
        $stats->{ $prop->type }->{ $prop_acc } = $prop->name;
     }
  }

  open(AS, ">", "$outdir/stats.SUMMARY") or die "Failed to open stats.overview\n";

  foreach my $type (@ORDER){
    print AS "$type\t".scalar(keys %{$stats->{ $type }})."\n";  
    open(S, ">", "$outdir/stats.$type") or die;
    foreach my $gp (sort keys %{ $stats->{ $type } }){
      print S "$gp\t$stats->{$type}->{$gp}\n";
    }
    close(S);
  }
  close(AS);

  return 1;
}

sub gp2db {
  my ($gp, $schema) = @_;

  my $retryMax;
  if($gp->get_defs){
     my @gps = sort keys %{$gp->get_defs};
     


     for (my $i=0; $i <= $#gps; $i++) {
        my $prop_acc = $gps[$i]++;
        my $prop = $gp->get_def($prop_acc);
        
        # Need to see if this has any deps.
        
        
        my $row = 
        $schema->resultset('GenomeProperty')->update_or_create( 'accession'   => $prop_acc,
                                                                'description' => $prop->name,
                                                                'type'        => $prop->type,
                                                                'author'      => $prop->author,
                                                                'threshold'   => $prop->threshold,
                                                                'comment'     => $prop->comment,
                                                                'private'     => defined($prop->private) ? $prop->private : undef,
                                                                'ispublic'    => $prop->public,
                                                                'checked'     => 1); #TODO - checked is hard coded to 1.
        eval {  
          addReferences2DB($prop->refs, $prop_acc, $schema); 
          addDBrefs2DB($prop->dbrefs, $prop_acc, $schema); 
          addSteps2DB( $prop->get_steps, $prop_acc, $schema);      
        };
        if($@) {
          if(defined($retryMax->{$prop_acc}) and $retryMax->{$prop_acc}->{count} <5){
            $retryMax->{$prop_acc}->{count}++;
            $retryMax->{$prop_acc}->{reason} .= $@;
            push(@gps, $prop_acc);
          }elsif(!defined($retryMax->{$prop_acc})){
            $retryMax->{$prop_acc}->{count}++;
            $retryMax->{$prop_acc}->{reason} .= $@; 
            push(@gps, $prop_acc);
          }else{
            die "Failed to add $prop_acc because ".$retryMax->{$prop_acc}->{reason}."\n";
          }
        }
     }


  }


}

sub addReferences2DB {
  my ($refs, $prop_acc, $schema) = @_;
  
  #First add all of the articles to the database. We do not care if an article is not longer used,
  #we just want to keep adding any new items.
  foreach my $ref (@$refs){
    $schema->resultset('LiteratureReference')->update_or_create('pmid'    => $ref->{RM},
                                                                'title'   => $ref->{RT},
                                                                'author'  => $ref->{RA},
                                                                'journal' => $ref->{RL} );  
  }

  #Now delete all of the links between
  $schema->resultset('GpLitRef')->search({'gp_accession' => $prop_acc})->delete;  
  foreach my $ref (@$refs){
    $schema->resultset('GpLitRef')->create({'gp_accession' => $prop_acc,
                                           'literature_reference_pmid' => $ref->{RM},
                                           'list_order' => $ref->{RN} });  
  }
}

sub addDBrefs2DB {
  my ($dbrefs, $prop_acc, $schema) = @_;

  #Now delete all of the links between
  $schema->resultset('GpDatabaseLink')->search({'gp_accession' => $prop_acc})->delete;  
  foreach my $ref (@$dbrefs){
    $schema->resultset('GpDatabaseLink')->create({'gp_accession' => $prop_acc,
                                                  'db_id' => $ref->{db_id},
                                                  'db_link' => $ref->{db_link},  
                                                  'other_params' => defined($ref->{other_params})? $ref->{other_params} : undef,
                                                  'comment' => defined($ref->{db_comment}) ? $ref->{db_comment} : undef });
  }
}

sub addSteps2DB {
  my ($steps, $prop_acc, $schema) = @_; 
  
  
  $schema->resultset('GpStep')->search({'gp_accession' => $prop_acc})->delete;  
  
  foreach my $step (@$steps ){
    #Insert the row....
    my $GpStep = $schema->resultset('GpStep')->create({'gp_accession' => $prop_acc,  
                                                       'required'     => $step->required,
                                                       'step_number'  => $step->order,
                                                       'step_id'      => $step->step_name,
                                                       'step_display_name' => $step->alter_name});
    
   	my $ua = LWP::UserAgent->new;
 		$ua->timeout(10);
 		$ua->env_proxy;
    $ua->ssl_opts( 'verify_hostname' => 0 );
    
    foreach my $evidence (@{$step->get_evidence}){
      my $gos = $evidence->get_go;
      foreach my $go ( @$gos ){
        my $go_row = $schema->resultset('GoTerm')->find({ 'go_id' => $go } );
        if(!$go_row){
 		      my $response = $ua->get("https://www.ebi.ac.uk/ols/api/ontologies/go/terms?obo_id=$go"); 
		      if ($response->is_success) {
            my $goInfo = from_json( $response->content );
            my $cat = $goInfo->{_embedded}->{terms}->[0]->{annotation}->{has_obo_namespace};
            if(!defined($cat)){
              $cat = "obsolete";
            }
            my $text = $goInfo->{_embedded}->{terms}->[0]->{label};
            $schema->resultset('GoTerm')->create({ 'go_id' => $go, 'term' => $text, 'category' => $cat});
 		      } else {
            die "Failed to find the GO term $go in GP $prop_acc\n";
          }
        }
      }
      
      #Find the GP terms and add them to the GO table
      if($evidence->gp){
        #Put this in the GP table....
        my $GPevidence = $schema->resultset('GpStepEvidenceGp')->create({ 'auto_step' => $GpStep->auto_step,
                                                                          'gp_accession' => $evidence->gp });
        foreach my $go (@$gos){
          $schema->resultset('GpStepToGo')->create({'auto_gp_step' => $GPevidence->auto_ipr_step,
                                                    'go_id'        => $go });
        }
      }else{
        #Put this evidence in the InterPro table
        my $iprEvid = $schema->resultset('GpStepEvidenceIpr')->create({ 'auto_step' => $GpStep->auto_step,
                                                                         'interpro_acc' => $evidence->interpro,
                                                                         'sufficient' => (defined($evidence->type) and $evidence->type eq 'sufficient') ? 1 : 0,
                                                                         'signature_acc' => $evidence->accession });
        foreach my $go (@$gos){
          $schema->resultset('IprStepToGo')->create({'auto_ipr_step' => $iprEvid->auto_ipr_step,
                                                     'go_id'         => $go });
        }
      }
    }
  }


}

1;
