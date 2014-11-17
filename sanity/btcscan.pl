#!/usr/bin/perl

use strict;
use warnings;
use Try::Tiny;
use Data::Dumper;

use RDF::Trine qw(iri);
use RDF::Trine::Parser::NQuads;
use RDF::Trine::Namespace;
use RDF::Trine::Store::DBI;

my $dsn = "DBI:Pg:database=sanity";
my $dbh = DBI->connect( $dsn, 'kjetil');

my $store = RDF::Trine::Store::DBI->new( 'btc', $dbh );

my $model = RDF::Trine::Model->new($store);

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
	if($st->predicate->equal($httpo->expires) ||
		 $st->predicate->equal($httpo->etag) ||
		 $st->predicate->equal(iri("$httpo" . 'last-modified')) ||
		 ($st->predicate->equal(iri("$httpo" . 'content-type')) && ($st->object->as_string =~ m/turtle|rdf\+xml|rdf\+n3/))
	  ) {
		$counts{added}++;
		$model->add_statement($st);
	} #else {
	#	warn "Didn't add " . $st->as_string;
	#}
};

my @files = glob "/home/kjetil/Projects/SemWeb/data/btc-2014/headers/*/headers.nx*";

foreach my $filename (@files) {
	open (my $file, "<", $filename) or die $!;

	while (<$file>) { # Need to do groundwork ourselves due to invalid data
		my $line = $_;
		$counts{total}++;
		next unless $line =~ m/expires|etag|last-modified|turtle|rdf\+xml|rdf\+n3/i;
		$counts{initial}++;
		try {
			$parser->parse( 'http://robin:5000', $line, $handler);
		} catch {
			#		warn "Parse failed for $line: $_";
			$counts{failures}++;
			next;
		};
	}
}


print Dumper(\%counts);
print $model->size . "\n";

