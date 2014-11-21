#!/usr/bin/perl

use strict;
use warnings;
no warnings "exiting";
use Try::Tiny;
use Data::Dumper;
use PerlIO::gzip;

use RDF::Trine qw(iri);
use RDF::Trine::Parser::NQuads;
use RDF::Trine::Namespace;
#use RDF::Trine::Store::DBI;
use RDF::Trine::Store::File::Quad;

#my $dsn = "DBI:Pg:database=sanity";
#my $dbh = DBI->connect( $dsn, 'kjetil');

#my $store = RDF::Trine::Store::DBI->new( 'btc', $dbh );
my $store = RDF::Trine::Store::File::Quad->new_with_string( 'File::Quad;/mnt/ssdstore/data/btc-processed/data1.nq' );

my $model = RDF::Trine::Model->new($store);

$model->begin_bulk_ops;

#use Module::Load::Conditional qw[can_load];
#
#print STDERR can_load( modules => 'RDF::Trine::Node::Literal::XML' )
#        ? 'Literal::XML is installed, could croak'
#        : 'OK, no XML parsing';
#print STDERR "\n";

#use PerlIO::gzip;
#open (my $zipfile, "<:gzip", "/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-0.gz") or die $!;

my $parser     = RDF::Trine::Parser::NQuads->new(canonicalize => 0) ;
my $httpo = RDF::Trine::Namespace->new('http://www.w3.org/2006/http#');

my %counts = ( failures => 0,
					total => 0,
					initial => 0,
					added => 0
				 );



my $handler = sub {
	my $st = shift;
	if (
		 ($st->predicate->equal(iri('http://www.w3.org/ns/sparql-service-description#endpoint'))
		  && $st->object->is_resource) ||
		 ($st->object->equal(iri('http://vocab.deri.ie/cogs#Endpoint')) 
		  && $st->subject->is_resource) ||
		 ($st->object->equal(iri('http://www.w3.org/2002/07/owl#Ontology'))		  
		  && $st->subject->is_resource) ||
		 (($st->predicate =~ m/sparql/i) && ($st->predicate !~ m/sparql-service-description/i) && 
		  $st->subject->is_resource && $st->object->is_resource) ||
		 (($st->predicate->equal(iri('http://rdfs.org/ns/void#vocabulary')) && $st->object->is_resource)) ||
		 (($st->predicate->equal(iri('http://www.w3.org/ns/rdfa#vocabulary')) && $st->object->is_resource)) ||
		 (($st->predicate->equal(iri('http://purl.org/linked-data/api/vocab#vocabulary')) && $st->object->is_resource)) ||
		 ($st->object->equal(iri('http://purl.org/vocommons/voaf#Vocabulary'))
		  && $st->subject->is_resource)
	  ) {
		$counts{added}++;
		$model->add_statement($st);
	} #else {
		#warn "Didn't add " . $st->as_string;
	#}
};

my @files = (
'/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-0.gz'
        );


foreach my $filename (@files) {
	open (my $file, "<:gzip", $filename) or die $!;
	print STDERR "Starting on file $filename\n";
	while (<$file>) { # Need to do groundwork ourselves due to invalid data
		my $line = $_;
		$counts{total}++;
		next unless $line =~ m/ontology|endpoint|sparql|vocabular/i;
		$counts{initial}++;
		print STDERR $counts{initial} ."\n" if ($counts{initial} % 10000 == 0);
		try {
			$parser->parse( 'http://robin:5000', $line, $handler);
		} catch {
#					warn "Parse failed for $line: $_";
					$counts{failures}++;
					next;
		};
	}
	print STDERR "Finished file $filename\n";
	close $file;
}

$model->end_bulk_ops;

print Dumper(\%counts);
print $model->size . "\n";

