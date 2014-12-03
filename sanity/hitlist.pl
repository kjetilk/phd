#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;
use Data::Dumper;
use RDF::Query::Client;
use URI;
use RDF::Trine qw(statement iri literal);
use URI::NamespaceMap;
use Scalar::Util qw(blessed);
use RDF::Trine::Store::DBI;
use Progress::Any::Output;
Progress::Any::Output->set('TermProgressBarColor');
use Progress::Any;   

my $progress = Progress::Any->get_indicator(
        task => "scanning", target=>1460000);

$progress->update(message => "Setting up");

#my $dsn = "DBI:Pg:database=sanity";
#my $dbh = DBI->connect( $dsn, 'kjetil');

#my $store = RDF::Trine::Store::DBI->new( 'hitlist', $dbh );
#my $om = RDF::Trine::Model->new($store);


my $nm = URI::NamespaceMap->new(['dct', 'rdfs', 'void', 'rdf']);
my $dct = $nm->namespace_uri('dct');
my $rdfs = $nm->namespace_uri('rdfs');
my $rdf = $nm->namespace_uri('rdf');
my $void = $nm->namespace_uri('void');
my $om = RDF::Trine::Model->temporary_model;

my %known_vocabs = ('http://invalid/' => 1);
my %known_endpoints = ('http://invalid/' => 1);
my %known_datasets = ('http://invalid/' => 1);

sub normalize_uri {
	my $url = shift;
	my $uri;
	if (blessed($url)) {
		if ($url->isa('RDF::Trine::Node::Resource')) {
			$uri = URI->new($url->uri_value);
		}
		elsif ($url->isa('URI')) {
			$uri = $url;
		}
	}
	$uri = URI->new($url);
	return iri('http://invalid/') unless defined($uri->scheme);
	return iri('http://invalid/') unless ($uri->scheme eq 'http' || $uri->scheme eq 'https');
	return iri('http://invalid/') if ($uri->host eq 'localhost' || 
													  $uri->host =~ m/^(?:10\.|192\.168\.|172\.|127\.)/);

	$uri = $uri->canonical;
	return iri($uri->scheme .':'. $uri->opaque);
}

my $pos = 10;
$progress->pos($pos);
$progress->update(message => "Reading prefix.cc URLs");

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", "/home/kjetil/Projects/SemWeb/data/all.file.csv" or die "all.file.csv: $!";
while ( my $row = $csv->getline( $fh ) ) {
	$pos++;
	$progress->pos($pos);
	my $url = normalize_uri($row->[1]);
	$known_vocabs{$url->uri_value} = 1; # To speed things up later
	$om->add_statement(statement($url, iri($dct->source), iri('http://prefix.cc/')));
	$om->add_statement(statement($url, iri($dct->type), literal('vocabulary')));
}

$csv->eof or $csv->error_diag();
close $fh;

$progress->update(message => "Querying LOV for vocabs");

my $query = RDF::Query::Client->new('SELECT DISTINCT ?vocabURI ?nsURI WHERE { ?vocabURI a <http://purl.org/vocommons/voaf#Vocabulary> ; <http://purl.org/vocab/vann/preferredNamespaceUri> ?nsURI . }');

my $iterator = $query->execute('http://lov.okfn.org/endpoint/lov');

$pos+=10;
$progress->pos($pos);

while (my $row = $iterator->next) {
	$pos++;
	$progress->pos($pos);
   my $vocaburi = $row->{vocabURI};
	my $vocaburinorm = normalize_uri($vocaburi);
   my $nsURI = $row->{nsURI};
   my $nsURInorm = normalize_uri($row->{nsURI});

	$known_vocabs{$nsURInorm->uri_value} = 1; # To speed things up later
	$om->add_statement(statement($nsURInorm, iri($dct->source), iri('http://lov.okfn.org/')));
	$om->add_statement(statement($nsURInorm, iri($dct->type), literal('vocabulary')));
	unless ($nsURInorm->equal($vocaburinorm) || $nsURI->equal($vocaburi)) {
		$known_vocabs{$vocaburinorm->uri_value} = 1; # To speed things up later
		$om->add_statement(statement($nsURInorm, iri($dct->identifier), $vocaburinorm));
	}
}

my $onts;

sub datahandler {
	my $st = shift;
	$pos++;
	$progress->pos($pos);
	if	(
		 $st->predicate->equal(iri('http://logd.tw.rpi.edu/node#field_sparqlendpoint')) ||
		 $st->predicate->equal(iri('http://purl.org/openorg/sparql')) ||
		 $st->predicate->equal(iri('http://www.w3.org/ns/sparql-service-description#endpoint'))) {
		my $uri = normalize_uri($st->object);
		unless ($known_endpoints{$uri->uri_value}) {
			$known_endpoints{$uri->uri_value} = 1;
			$om->add_statement(statement($uri, iri($dct->source), $st->predicate));
			$om->add_statement(statement($uri, iri($dct->type), literal('endpoint')));
		}
	} elsif ($st->predicate->equal(iri('http://rdfs.org/ns/void#vocabulary'))) {
		my $vocab = normalize_uri($st->object);
		unless ($known_vocabs{$vocab->uri_value}) {
			$known_vocabs{$vocab->uri_value} = 1;
			$om->add_statement(statement($vocab, iri($dct->source), $st->predicate));
			$om->add_statement(statement($vocab, iri($dct->type), literal('vocabulary')));
		}
		my $dataset = normalize_uri($st->subject);
		unless ($known_datasets{$dataset->uri_value}) {
			$known_datasets{$dataset->uri_value} = 1;
			$om->add_statement(statement($dataset, iri($dct->source), $st->predicate));
			$om->add_statement(statement($dataset, iri($dct->type), literal('dataset')));
		}
	} elsif ($st->predicate->equal(iri('http://rdfs.org/ns/void#sparqlEndpoint'))) {
		my $endpoint = normalize_uri($st->object);
		unless ($known_endpoints{$endpoint->uri_value}) {
			$known_endpoints{$endpoint->uri_value} = 1;
			$om->add_statement(statement($endpoint, iri($dct->source), $st->predicate));
			$om->add_statement(statement($endpoint, iri($dct->type), literal('endpoint')));
		}
		my $dataset = normalize_uri($st->subject);
		unless ($known_datasets{$dataset->uri_value}) {
			$known_datasets{$dataset->uri_value} = 1;
			$om->add_statement(statement($dataset, iri($dct->source), $st->predicate));
			$om->add_statement(statement($dataset, iri($dct->type), literal('dataset')));
		}
	} elsif ($st->predicate->equal(iri($rdf->type))) {
		my $vocab = normalize_uri($st->subject);
		if (! $known_vocabs{$vocab->uri_value}) {
			if ($st->object->equal(iri('http://www.w3.org/2002/07/owl#Ontology'))) {
				my $vocabhost = URI->new($vocab->uri_value)->host;
				push (@{$onts->{$vocabhost}}, $vocab);
			}
			elsif ($st->object->equal(iri('http://purl.org/vocommons/voaf#Vocabulary'))) {
				$known_vocabs{$vocab->uri_value} = 1;
				$om->add_statement(statement($vocab, iri($dct->source), $st->object));
				$om->add_statement(statement($vocab, iri($dct->type), literal('vocabulary')));
			}
				

		}
	}
}

$progress->target(1451234);
my $nqparser = RDF::Trine::Parser::NQuads->new;
foreach my $filename (glob "/mnt/ssdstore/data/btc-processed/data*.nq") {
	$progress->update(message => "Parsing $filename");
	$nqparser->parse_file( '', $filename, \&datahandler);
}

$progress->update(message => "Sampling ontologies per host");
$progress->target(1460000 + scalar keys %{$onts});
$pos+=5;
$progress->pos($pos);

while ((my $host, my $vocabs) = each(%{$onts})) {
	$pos++;
	$progress->pos($pos);
	my @onts = @{$vocabs};
	my $rvocab = $onts[int(rand(scalar @onts))];
	$om->add_statement(statement($rvocab, iri($dct->source), iri('http://www.w3.org/2002/07/owl#Ontology')));
	$om->add_statement(statement($rvocab, iri($dct->type), literal('vocabulary')));
}


$progress->update(message => "Serializing the results");
open ($fh, ">", "/mnt/ssdstore/data/btc-processed/hitlist-data.ttl") or die "Couldn't open file for write";
my $ser = RDF::Trine::Serializer->new('turtle', namespaces => { 'dct' => $dct->uri->as_string,
 																				    'owl' => 'http://www.w3.org/2002/07/owl#',
 																					 'void' => 'http://rdfs.org/ns/void#'
 																				  });
$pos+=5;
$progress->pos($pos);
print $ser->serialize_model_to_file($fh, $om);
close $fh;
$progress->finish;

