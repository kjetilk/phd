#!/usr/bin/perl

use strict;
use warnings;

use Module::Load::Conditional qw[can_load];

print STDERR can_load( modules => 'RDF::Trine::Node::Literal::XML' )
        ? 'Literal::XML is installed, could croak'
        : 'OK, no XML parsing';
print STDERR "\n";

use PerlIO::gzip;
open (my $zipfile, "<:gzip", "/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-0.gz") or die $!;

use RDF::Trine;
use RDF::Trine::Parser::NQuads;

my $model = RDF::Trine::Model->temporary_model;
 
my $parser     = RDF::Trine::Parser::NQuads->new(canonicalize => 0) ;
 
$parser->parse_file_into_model( 'http://robin:5000', $zipfile, $model );


print $model->size . "\n";

