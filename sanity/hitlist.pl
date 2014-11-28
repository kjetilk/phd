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

my $nm = URI::NamespaceMap->new(['dct', 'rdfs', 'void']);
my $dct = $nm->namespace_uri('dct');
my $rdfs = $nm->namespace_uri('rdfs');
my $void = $nm->namespace_uri('void');
my $om = RDF::Trine::Model->temporary_model;

my %known_vocabs;
my %known_endpoints;
my %known_datasets;

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
	$uri = $uri->canonical;
	return iri($uri->scheme . $uri->opaque);
}

#if (0) {
print STDERR "Reading prefix.cc URLs\n";

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", "/home/kjetil/Projects/SemWeb/data/all.file.csv" or die "all.file.csv: $!";
while ( my $row = $csv->getline( $fh ) ) {
	my $url = normalize_uri($row->[1]);
	$known_vocabs{$url->uri_value} = 1; # To speed things up later
	$om->add_statement(statement($url, iri($dct->source), iri('http://prefix.cc/')));
	$om->add_statement(statement($url, iri($dct->type), literal('vocabulary')));
}

$csv->eof or $csv->error_diag();
close $fh;

print STDERR "Querying LOV for vocabs\n";

my $query = RDF::Query::Client->new('SELECT DISTINCT ?vocabURI ?nsURI WHERE { ?vocabURI a <http://purl.org/vocommons/voaf#Vocabulary> ; <http://purl.org/vocab/vann/preferredNamespaceUri> ?nsURI . }');

my $iterator = $query->execute('http://lov.okfn.org/endpoint/lov');

while (my $row = $iterator->next) {
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

sub datahandler {
	my $st = shift;
	if	($st->predicate->equal(iri('http://www.w3.org/ns/sparql-service-description#endpoint'))) {
		my $uri = $st->object;
		unless ($known_endpoints{$uri->uri_value}) {
			$known_endpoints{$uri->uri_value} = 1;
			$om->add_statement(statement($uri, iri($dct->source), $st->predicate));
			$om->add_statement(statement($uri, iri($dct->type), literal('endpoint')));
		}
	} elsif ($st->predicate->equal(iri('http://rdfs.org/ns/void#vocabulary'))) {
		my $vocab = $st->object;
		unless ($known_vocabs{$vocab->uri_value}) {
			$known_vocabs{$vocab->uri_value} = 1;
			$om->add_statement(statement($vocab, iri($dct->source), $st->predicate));
			$om->add_statement(statement($vocab, iri($dct->type), literal('vocabulary')));
		}
		
#		my $dataset = $st->subject;
	}
#	die $om->as_string if $om->size > 5;

}
			


my $nqparser = RDF::Trine::Parser::NQuads->new;
foreach my $filename (glob "/mnt/ssdstore/data/btc-processed/data*.nq") {
	print STDERR "Parsing $filename\n";
	$nqparser->parse_file( '', $filename, \&datahandler);
}


print STDERR "Serializing the results\n";
my $ser = RDF::Trine::Serializer->new('turtle', namespaces => { 'dct' => $dct->uri->as_string });
print $ser->serialize_model_to_string($om);
