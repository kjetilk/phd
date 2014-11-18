#!/usr/bin/perl

use strict;
use warnings;
use Try::Tiny;
use Data::Dumper;
use Fcntl qw(:flock);

use RDF::Trine qw(iri);
use RDF::Trine::Parser::NQuads;
use RDF::Trine::Namespace;
use RDF::Trine::Store::DBI;

my $dsn = "DBI:Pg:database=sanity";
my $dbh = DBI->connect( $dsn, 'kjetil');

my $store = RDF::Trine::Store::DBI->new( 'btc', $dbh );

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

my @files = (
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/01/headers.nx-6',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/01/headers.nx-7',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/01/headers.nx-8',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/01/headers.nx-9',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-0',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-1',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-10',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-11',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-12',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-13',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-14',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-15',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-2',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-3',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-4',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-5',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-6',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-7',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-8',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/02/headers.nx-9',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/03/headers.nx-0',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/04/headers.nx-0',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/05/headers.nx-0',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/05/headers.nx-1',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/06/headers.nx-0',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/07/headers.nx-0',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/07/headers.nx-1',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/07/headers.nx-2',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/07/headers.nx-3',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/08/headers.nx-0',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/09/headers.nx-0',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/09/headers.nx-1',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/10/headers.nx-0',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/10/headers.nx-1',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/10/headers.nx-2',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/10/headers.nx-3',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/11/headers.nx-0',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/11/headers.nx-1',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/11/headers.nx-2',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/11/headers.nx-3',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/11/headers.nx-4',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/11/headers.nx-5',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/11/headers.nx-6',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/11/headers.nx-7',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/12/headers.nx-0',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/13/headers.nx-0',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/14/headers.nx-0'
        );


foreach my $filename (@files) {
	open (my $file, "<", $filename) or die $!;
	flock ($file, LOCK_EX) or next;
	print STDERR "Starting on file $filename\n";
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
		print STDERR $counts{total} ."\n" if ($counts{total} % 10000 == 0);
	}
	print STDERR "Finished file $filename\n";
	close $file;
}

$model->end_bulk_ops;

print Dumper(\%counts);
print $model->size . "\n";

