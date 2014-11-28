#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;
use Data::Dumper;
use RDF::Query::Client;
use URI;
use RDF::Trine qw(statement iri literal);
use URI::NamespaceMap;

my $nm = URI::NamespaceMap->new(['dct']);
my $dct = $nm->namespace_uri('dct');
my $om = RDF::Trine::Model->temporary_model;


print STDERR "Reading prefix.cc URLs\n";

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", "/home/kjetil/Projects/SemWeb/data/all.file.csv" or die "all.file.csv: $!";
while ( my $row = $csv->getline( $fh ) ) {
	my $url = $row->[1];
	$om->add_statement(statement(iri($url), iri($dct->source), iri('http://prefix.cc/')));
	$om->add_statement(statement(iri($url), iri($dct->type), literal('vocabulary')));
}

$csv->eof or $csv->error_diag();
close $fh;

print STDERR "Querying LOV for vocabs\n";

my $query = RDF::Query::Client->new('SELECT DISTINCT ?vocabURI ?nsURI WHERE { ?vocabURI a <http://purl.org/vocommons/voaf#Vocabulary> ; <http://purl.org/vocab/vann/preferredNamespaceUri> ?nsURI . }');

my $iterator = $query->execute('http://lov.okfn.org/endpoint/lov');

while (my $row = $iterator->next) {
   my $url1 = URI->new($row->{vocabURI}->as_string);
   my $url2 = URI->new($row->{nsURI}->as_string);
	$om->add_statement(statement(iri($url2), iri($dct->source), iri('http://lov.okfn.org/')));
	$om->add_statement(statement(iri($url2), iri($dct->type), literal('vocabulary')));
	my $url3 = URI->new($url1->as_string . '#');
	unless ($url2->eq($url1) || $url2->eq($url3)) {
		$om->add_statement(statement(iri($url2), iri($dct->identifier), iri($url1)));
	}
}


print STDERR "Serializing the results\n";
my $ser = RDF::Trine::Serializer->new('turtle', namespaces => { 'dct' => $dct->uri->as_string });
print $ser->serialize_model_to_string($om);
