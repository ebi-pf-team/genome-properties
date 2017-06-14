#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Clone 'clone';
use DDP;
use GenomePropertiesIO;

my $file = shift;
my $gp = GenomeProperties->new;
GenomePropertiesIO::parseDESC($file, $gp);
p($gp);

