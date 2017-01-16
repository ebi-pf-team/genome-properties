package GenomeProperties::StepEvidence;

sub new {
  my $class = shift;
  my $hashRef = shift;  
  my $self = {};
   #Need to check that this does not go out of scope! 
  $self=$hashRef;

  bless( $self, $class);
  
  return $self;

}

sub type {
  my ($self) = @_;
  
  return $self->{type};

}

sub accession {
  my ($self) = @_;  
  return $self->{accession};
}


sub step_ev_id {
  my ($self) = @_;  
  return $self->{step_ev_id};
}


sub step {
  my ($self) = @_;  
  return $self->{step};
}


sub get_go {
  my ($self) = @_;  
  return $self->{get_go};
}

sub interpro {
  my ($self) = @_;  
  return $self->{interpro};
}
1;
