#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Clone 'clone';
use DDP;
use GenomeProperties;

my $file = shift;
my $gp = GenomeProperties->new;

parseDESC($file, $gp);


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
    p($l);
    if ( length($l) > $expLen ) {
      confess( "\nGot a DESC line that was longer the $expLen, $file[$i]\n\n"
          . "-" x 80
          . "\n" );
    }

    if ( $file[$i] =~ /^(AC|DE|AU|TP|TH|)\s{2}(.*)$/ ) {
      if(exists($params{$1})){
        confess("\nFound more than one line containing the $1 tag\n\n"
         . "-" x 80
                . "\n" );  
      }
      $params{$1} = $2;
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
          my ($nextTag) = $file[ $j + 1 ] =~ /^(\w{2})\s{2}/;

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
    }else {
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
  print "$file, $i\n";
  my @steps;
  my %step;
  for (  ; $$i <scalar(@{$file}) ; $$i++ ) {
    
    my $l = $file->[$$i];
    chomp($l);
    p($l);
    if ( length($l) > $expLen ) {
      confess( "\nGot a DESC line that was longer the $expLen, $l\n\n"
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
        my $go = '';
        if($nl =~ /^TG\s{2}(GO\:\d+)/){
          $go = $1;
          $$i++;
        }
        push(@{$step{EVID}}, { ipr => $ipr, sig => $sig, sc => $suf, go => $go });
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
