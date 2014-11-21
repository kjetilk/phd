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
#my $store = RDF::Trine::Store::File::Quad->new_with_string( 'File::Quad;/mnt/ssdstore/data/btc-processed/data1.nq' );
my $store = RDF::Trine::Store::File::Quad->new_with_string( 'File::Quad;/mnt/ssdstore/data/btc-processed/data2.nq' );

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
			 # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-0.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-1.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-10.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-2.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-00.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-01.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-02.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-03.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-04.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-05.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-06.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-07.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-08.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-3-09.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-4.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-5.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-6.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-7.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-8.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/01/data.nq-9.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-0.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-1.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-10.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-11.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-12.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-13.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-14.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-15.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-2.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-3.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-4.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-5.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-6.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-7.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-8.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/02/data.nq-9.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/03/data.nq-0.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/04/data.nq-0.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-00.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-01.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-02.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-03.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-04.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-05.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-06.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-07.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-08.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-09.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-10.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-11.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-12.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-13.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-14.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-15.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-16.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-17.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-18.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-19.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-20.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-21.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-22.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-23.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-24.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-25.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-26.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-27.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-28.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-29.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-30.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-31.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-32.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-33.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-34.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-35.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-0-36.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-00.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-01.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-02.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-03.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-04.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-05.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-06.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-07.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-08.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-09.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-10.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-11.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-12.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-13.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-14.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-15.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-16.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-17.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-18.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-19.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-20.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-21.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-22.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-23.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-24.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-25.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/05/data.nq-1-26.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/06/data.nq-0.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-00.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-01.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-02.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-03.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-04.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-05.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-06.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-07.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-08.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-09.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-10.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-11.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-12.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-13.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-14.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-15.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-16.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-17.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-18.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-19.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-0-20.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-00.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-01.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-02.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-03.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-04.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-05.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-06.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-07.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-08.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-09.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-10.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-11.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-12.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-1-13.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-2.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/07/data.nq-3.gz',
          # '/home/kjetil/Projects/SemWeb/data/btc-2014/data/08/data.nq-0.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-00.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-01.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-02.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-03.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-04.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-05.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-06.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-07.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-08.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-09.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-10.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-11.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-12.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-13.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-14.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-15.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-16.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-17.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-18.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-19.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-20.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-21.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-22.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-23.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-24.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-25.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-26.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-27.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-28.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-29.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-30.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-31.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-32.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-0-33.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-00.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-01.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-02.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-03.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-04.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-05.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-06.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-07.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-08.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-09.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-10.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-11.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-12.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-13.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-14.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-15.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-16.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-17.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-18.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-19.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-20.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-21.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-22.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-23.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-24.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-25.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-26.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-27.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-28.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/09/data.nq-1-29.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-00.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-01.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-02.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-03.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-04.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-05.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-06.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-07.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-08.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-0-09.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-1.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-2.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/10/data.nq-3.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/11/data.nq-0.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/11/data.nq-1.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/11/data.nq-2.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/11/data.nq-3.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/11/data.nq-4.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/11/data.nq-5.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/11/data.nq-6.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/11/data.nq-7.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/12/data.nq-0.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-000.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-001.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-002.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-003.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-004.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-005.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-006.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-007.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-008.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-009.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-010.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-011.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-012.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-013.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-014.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-015.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-016.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-017.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-018.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-019.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-020.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-021.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-022.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-023.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-024.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-025.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-026.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-027.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-028.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-029.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-030.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-031.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-032.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-033.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-034.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-035.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-036.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-037.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-038.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-039.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-040.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-041.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-042.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-043.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-044.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-045.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-046.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-047.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-048.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-049.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-050.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-051.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-052.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-053.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-054.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-055.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-056.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-057.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-058.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-059.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-060.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-061.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-062.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-063.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-064.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-065.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-066.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-067.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-068.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-069.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-070.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-071.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-072.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-073.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-074.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-075.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-076.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-077.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-078.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-079.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-080.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-081.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-082.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-083.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-084.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-085.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-086.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-087.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-088.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-089.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-090.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-091.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-092.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-093.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-094.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-095.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-096.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-097.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-098.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-099.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-100.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-101.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-102.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-103.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-104.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-105.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-106.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-107.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-108.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-109.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-110.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-111.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-112.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-113.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-114.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-115.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-116.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-117.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-118.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-119.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-120.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-121.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-122.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-123.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/13/data.nq-0-124.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-00.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-01.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-02.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-03.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-04.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-05.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-06.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-07.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-08.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-09.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-10.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-11.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-12.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-13.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-14.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-15.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-16.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-17.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-18.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-19.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-20.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-21.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-22.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-23.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-24.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-25.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-26.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-27.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-28.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-29.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-30.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-31.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-32.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-33.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-34.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-35.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-36.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-37.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-38.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-39.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-40.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-41.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-42.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-43.gz',
          '/home/kjetil/Projects/SemWeb/data/btc-2014/data/14/data.nq-0-44.gz'
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

