#!/usr/bin/env perl
$|=1;
use strict;
use warnings;
use File::Slurp;
use LWP::UserAgent;
my $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => 0 } );
use DDP;

my $file = shift;
chomp($file);

my @paths = read_file($file);

foreach my $path (@paths){
  chomp($path);

#my $path= "PWY-6823";
my $url = "https://metacyc.org/META/NEW-IMAGE?type=NIL&object=".$path."&redirect=T";
my $response = $ua->get($url);
my $success = 0;


if ( $response->is_success ) {
    my $page = $response->decoded_content;
    if($page =~ m/Superclasses(.*)Summary/sm){
      my $bit = $1;
      my @cats = split(/\/td\>/, $bit);
      my @matches = $cats[1] =~ /\"\>(.*?)\<\/a\>/gsm;
      my $tab = '';
      print $path."\t".join("\t", @matches)."\n";
    }else{
      warn "Not matched, $path\n";
    }
} else {
    warn "$path not found\n";
}

}
