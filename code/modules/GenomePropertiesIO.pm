package GenomePropertiesIO;

use strict;
use warnings;
use Carp;
use Clone 'clone';
use DDP;
use LWP::UserAgent;

use GenomeProperties;

my %TYPES = ( METAPATH => 1,
              SYSTEM   => 1,
              GUILD    => 1,
              CATEGORY => 1,
              PATHWAY  => 1,
              SUMMARY  => 1,
              ROOT     => 1
              );

sub validateGP {
  my($gp, $options) = @_;
    
  #Read the DESC
	DESC:
  foreach my $dir (@{$options->{dirs}}){
    #TODO: put status check in here
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
		 		if($options->{status} =~ /public/ and $public != 1){
					next DESC;
				}
		 		if($options->{status} =~ /checked/ and $checked != 1){
					next DESC;
				}
			}
		}else{
			if(defined($options->{status})){
				warn "$dir has no status file, yet a status check is required. Skipping\n"
			}
		}


    eval{
      parseDESC("$dir/DESC", $gp);
    };
    if($@){
      print "$dir: does not pass check $@\n";
      open(E, ">", "$dir/error");
      print E "Error parsing DESC:\n $@\n";
      close(E);   
    }
  }

  #Does it have any steps that we should have a sequence for testing
  if($gp->get_defs){
     my @gpsToCheck = keys %{$gp->get_defs};
     
      
     foreach my $prop_acc (@gpsToCheck){
      my $errors = 0;   
      my $errorMsg = '';
      my $prop = $gp->get_def($prop_acc);
      
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
      my $moreGPsToCheck = _checkFASTA($prop, \$errors, \$errorMsg, $options, \@gpsToCheck);    
      
      if($moreGPsToCheck){
        foreach my $gpTA (@$moreGPsToCheck){
          parseDESC($gpTA."/DESC", $gp); 
          push(@gpsToCheck, $gp);
        }
      }

      
      if($errors){
        print "$prop_acc: does not pass check\n";
        open(E, ">", "$prop_acc/error");
        print E $errorMsg;
        close(E);
        print $errorMsg;
      }else{
        unlink("$prop_acc/error") if(-e "$prop_acc/error");
        print "$prop_acc: passes check\n";
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
          warn "Error parsing Fasta: $@\n";
          $$errorMsg .= $@;
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
              push(@gpsToCheck, $evidence->gp);
            }
          }else{
            if(!defined($all{$evidence->gp})){
              warn("Reference to ".$evidence->gp." found, but not checked validity.\n");  
            }
          }
        }else{
          die "Unknown evidence type\n";
        }
      }
    }
  }
  return(\@gpsToCheck);
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

sub _checkTypeAgainstStep {
  my ($prop, $errors, $errorMsg) = @_;

  my $noSteps = scalar(@{$prop->get_steps});
  if($prop->type eq 'ROOT' or $prop->type eq 'CATEGORY' or $prop->type eq 'SUMMARY'){
    if($noSteps > 0){
      $$errors++;
      $$errorMsg .= "Got type ".$prop->type." but this should not have any steps\n";
    }
  }

  if($prop->type eq 'GUILD' or $prop->type eq 'SYSTEM' 
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

 		my $response = $ua->get("http://www.ebi.ac.uk/ols/api/ontologies/go/terms?obo_id=$go"); 

		if ($response->is_success) {
  		$options->{goterms}->{$go}++
 		} else {
     	$$errors++;
			$$errorMsg .= "Failed to find the GO term $go\n";
      # $response->status_line;
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
      die "Failed to parse FASTA for $dir\n"; 
    }
  }
  close(F);
  return($seqs);

}




sub parseDESC {
  my ( $file, $gp ) = @_;

  my @file;
  if ( ref($file) eq "GLOB" ) {
    @file = <$file>;
  }
  else {
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
        warn("In ".$params{AC}."\n") if($params{AC}); 
        warn("\nFound more than one line containing the $1 tag.\n\n"
         . "-" x 80
                . "\n" );  
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
            $com = $1;
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
      my $steps = parseSteps(\@file, \$i);
      $params{STEPS} = $steps;
    }elsif($file[$i] =~ /^\/\//){
      last;
    
    } else {
      chomp( $file[$i] );
      my $msg = "Failed to parse the DESC line (enclosed by |):|$file[$i]|\n\n"
        . "-" x 80 . "\n";

      #croak($msg);
      die $msg;

#confess("Failed to parse the DESC line (enclosed by |):|$file[$i]|\n\n". "-" x 80 ."\n");
    }
  }
 #print Dumper %params;
  $gp->fromDESC(\%params);
  #End of uber for loop
}


sub parseSteps {
  my($file, $i) = @_;
  my $expLen=80;
  my @steps;
  my %step;
  for (  ; $$i <scalar(@{$file}) ; $$i++ ) {
    
    my $l = $file->[$$i];
    chomp($l);
    if ( length($l) > $expLen ) {
      warn( "\nGot a DESC line that was longer the $expLen, $l\n\n"
          . "-" x 80
          . "\n" );
    }

    if ( $l =~ /^(SN|ID|DN|EC|RQ)\s{2}(.*)$/ ) {
      if(exists($step{$1})){
        confess("\nFound more than one line containing the $1 tag\n\n"
         . "-" x 80
                . "\n" );  
      }
      $step{$1} = $2;
      next;
    }elsif($l =~ /^EV\s{2}(IPR\d{6});\s(\S+);\s(\S+);/){
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
    }elsif($l =~ /^EV\s{2}(IPR\d{6});\s(\S+);/){
        my $ipr = $1;
        my $sig = $2;
        my $nl = $file->[$$i + 1];
        my $go = [];
        while($nl =~ /^TG\s{2}(GO\:\d+)/){
          push(@$go, $1);
          $$i++;
          $nl = $file->[$$i + 1];
        }
        push(@{$step{EVID}}, { ipr => $ipr, sig => $sig, go => $go });

    }elsif($l =~ /^EV\s{2}(GenProp\d{4});/){
        my $gp = $1;
        my $nl = $file->[$$i + 1];
        my $go = '';
        if($nl =~ /^TG\s{2}(GO\:\d+)/){
          $go = $1;
          $$i++;
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

1;
