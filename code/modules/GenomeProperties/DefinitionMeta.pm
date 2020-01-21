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

sub members {
  my ($self, @members) =@_;
  if (@members){
    $self->{_members} = \@members;
    }
  
  return($self->{_members});
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
