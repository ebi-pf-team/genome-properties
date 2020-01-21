package GenomeProperties::StepMeta;

sub new {
  my $class = shift;
  my $hashRef = shift;  
  my $self = {};
   #Need to check that this does not go out of scope! 
  $self=$hashRef;
  $self->{evidence} = [];
  $self->{skip}     = 0;
  $self->{found}    = 0;
  bless( $self, $class);
  return $self;

}


sub int_step_id {
  my( $self ) = @_;
  return($self->{int_step_id});
}

sub def_id {
  my( $self ) = @_;
  return($self->{def_id});
}

sub def_acc {
  my( $self ) = @_;
  return($self->{def_acc});
}

sub step_name {

  my( $self ) = @_;
  return($self->{step_name});
  
}

sub evaluated {
  my ( $self,$status ) = @_;

  if(defined($status)){
    $self->{_evaluated} = $status;
  }
  return $self->{_evaluated};
}

sub add_evidence {
  my ($self, $ev) =@_; 
  push(@{ $self->{evidence} }, $ev);
}

sub get_evidence {
  my($self) = @_;
  return($self->{evidence});
}

sub found {
  my ($self, @found) = @_;
  if(@found){
    $self->{found} = \@found;
    }
  return($self->{found});
}

sub skip {
  my ($self, $skip) = @_;
  if(defined($skip)){
    $self->{skip} = 1;
  }
  return($self->{skip});
}


sub required {
  my ($self) = @_;
  return $self->{required};
}

sub order {
  my ($self) = @_;
  return $self->{order};
}

sub in_rule {
  my ($self) = @_;
  return $self->{in_rule};
}


sub alter_name {
  my ($self) = @_;
  return $self->{alter_name};
}

1;
