package GenomeProperties::DefinitionMeta;

sub new {
  my $class = shift;
  my $hashRef = shift;  
  my $self = {};
   #Need to check that this does not go out of scope! 
  $self=$hashRef;
  $self->{steps} = [];
  $self->{_result} = 'UNTESTED';
  bless( $self, $class);
  
  return $self;

}

sub add_step {
  my ($self, $step) =@_;
  
  push(@{ $self->{steps} }, $step);
}

sub get_steps{
  my ($self) = @_;
  
  return $self->{steps};
}

sub evaluated {
  my ($self, $ev) = @_;

  if(defined($ev)){
    $self->{_evaluated} = $ev;
  }

  return($self->{_evaluated});
}

sub result {
  my ($self, $result) =@_;

  if(defined($result)){
    $self->{_result} = $result;
  }

  return($self->{_result});
    
}

sub refs {
  my ($self, $refs) = @_;
  if($refs){
    $self->{refs} = $refs;
  }
  
  return ($self->{refs});
}

sub parents {
  my ($self, $parents) = @_;
  if($parents){
    $self->{parents} = $parents;
  }
  
  return ($self->{parents});
}

sub dbrefs {
  my ($self, $dbrefs) = @_;
  if($dbrefs){
    $self->{dbrefs} = $dbrefs;
  }  
  return ($self->{dbrefs});
}

sub type {
  my ($self, $type) = @_;
  if(defined($type)){
    $self->{type} = $type;
  }
  return($self->{type});

}

sub map {
  my ($self) = @_;
  return($self->{map});
}

sub accession {
  my ($self) = @_;
  return($self->{accession});
}

sub name {
  my ($self) = @_;
  return($self->{name});
}

sub public {
  my ($self) = @_;
  return($self->{public});
}

sub threshold {
  my ($self, $threshold) = @_;
  if($threshold){
    $self->{threshold} = $threshold;
  }  
  return($self->{threshold});
}

sub method{
  my ($self) = @_;
  return($self->{method});
}

sub author {
  my ($self) = @_;
  return($self->{author});
}

sub comment {
  my ($self, $comment) = @_;
  if($comment){
    $self->{comment} = $comment;
  }
  return($self->{comment});
}

sub private {
  my ($self) = @_;
  return($self->{private});
}

sub minimum_subgroup {
  my ($self, $hash_ref) =@_;
  # We look for the combinations with the lower amount of jumps, the rest will be discarded.
  # During the evaluation process, for each step of a pathway, we get the members of the community that can perform it.
  # We will take every combination of these members (from step 1 to the last one) and calculate a score
  # based on the number of jumps that combination requires. This is a recursive process, the script will take one
  # member of the first step, construct one chain of members and evaluate its score. 
  # Then change the member of the last step, and calculate the new score. When all the members of a level were 
  # evaluated, the script will jump to the previous level and evaluate all the possibilities. Only the outcomes with
  # the best score are stored. The number of jumps is also calculated for every "sub chain": if the number of jumps
  # of a partial set of steps is bigger than the best score, it will be discarded and all the possible outcomes for
  # sub chain will not be evaluated
  
  my @best_paths;  

  # Since the best score and the best combinations are needed in every call of the subroutine "check_step_members",
  # we need to pass it by reference in each instance. To make things easier, I combined all that information in one array
  # which will have the best score in the position 0 and the list of combination with that score after that.
  $best_paths[0] = +Inf;
  if ((%$hash_ref) && (scalar (keys %$hash_ref) > 1)) {
    my %minimum = %$hash_ref;
    check_step_members($_, $hash_ref, 2, \@best_paths) for (@{$minimum{1}{members}}); # for each member in the step 1, check the members in step 2
    }
  elsif ((%$hash_ref) && (scalar (keys %$hash_ref) > 1)) { # In the case that there is only 1 step in the GP
    $best_paths[0]=0;
    push (@$best_paths, @{$minimum{1}{members}});
    }
  shift @best_paths;
  $self->{_minimum_subgroup} = \@best_paths;
  return($self->{_minimum_subgroup});
  }
  
sub check_step_members {
  my ($string_members, $hash_ref, $index, $out) =@_;
  my %minimum = %$hash_ref;

  foreach $m (@{$minimum{$index}{members}}) {
    my $required=1;
    my $last_required=1;
    my $sub_path = $string_members."; ".$m;
    my @sub_path = split "; ", $sub_path;
    my $sub_path_score =0;
    # There could be several consecutive not required steps in pathway.
    # To avoid counting a jump after a not required step/s, we store the last required result and compare against it

    $last_required = 0 if ($sub_path[0] =~ /\*$/);
    for (my $i=1; $i < (scalar @sub_path); $i++) {
      $required = 0 if ($sub_path[$i] =~ /\*$/);
      
      if ($sub_path[$i] ne $sub_path[$i-1]) {
        if ($required == 1 && $last_required == 1) { # If both steps are required, count it as a jump
          $sub_path_score+=1; 
          }
        else{ # If one of the steps is not required, compare the members and count it as a jump, but with a lower penalisation.
          my $prev_step = $sub_path[$i-1];
          $prev_step =~ s/\*$//;
          my $curr_step = $sub_path[$i];
          $curr_step =~ s/\*$//;
          $sub_path_score+=0.01 if ($prev_step ne $curr_step); 
          }
        }
      $last_required = $required;
      $required = 1;
      }
    
    if ($index < (scalar (keys %minimum))) { # If it's not the last step, calculate the score for that subset of steps. 
      next if ($sub_path_score > @{$out}[0]); # If its greater than the best score, discard it. Else go on with the nest step
      check_step_members($sub_path, $hash_ref, $index+1, $out);
      }
    else { # If it's the last step, calculate the final score and evaluate it.
      if ($sub_path_score < @{$out}[0]) {
        @{$out} = [];
        @{$out}[0] = $sub_path_score;
        @{$out}[1] = $sub_path;
        }   
      elsif ($sub_path_score == @{$out}[0]) {
        push (@$out, $sub_path);
        }
      }
    }    
  }

sub required_number {
  my ($self) = @_;
  return $$self->{required_number};
  }

sub checkConnection {
  my ($self, $gps, $connect) = @_;
  
  $connect->{$self->accession}++;
  foreach my $step (@{ $self->get_steps }){
   	foreach my $evidence (@{$step->get_evidence}){
      if($evidence->gp){
          my $def = $gps->get_def($evidence->gp);
					if($def){
						$def->checkConnection($gps, $connect);
					}
      } 
  	}
	}

}

1;
