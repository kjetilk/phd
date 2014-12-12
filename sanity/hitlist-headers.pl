#!/usr/bin/perl

use strict;
use warnings;

use URI;
use Data::Dumper;
use Progress::Any::Output;
Progress::Any::Output->set('TermProgressBarColor');
use Progress::Any;

my $progress = Progress::Any->get_indicator(
        task => "scanning", target => 31000000);

my $hosts;
$progress->update(message => "Setting up");

my $pos=0;
open my $fh, "<:encoding(utf8)", "/mnt/ssdstore/data/btc-processed/grepped" or die "grepped: $!";
while (<$fh>) {
	$pos++;
	$progress->update(message => "Scanning file");
	m!^(\S+?):\S+? \S+? \".+?\" <([^<>" {}|\\^`]+?)> .$!;
	my $filename = $1;
	my $resource = URI->new($2);
	my %entry = (filename => $filename,
					 resource => "$resource");
	my $host = $resource->host;
	if ($host =~ m/.*(livejournal.com|sapo.pt)/) {
		$host = $1;
	}
	push(@{$hosts->{$host}}, \%entry);
}
close $fh;

$progress->finish;

my $progser = Progress::Any->get_indicator(
        task => "serializing", target => 3+(scalar keys %{$hosts}));
my $files;

$progser->update(message => "Starting reorg");


use RDF::Trine qw(iri literal statement);
use RDF::Trine::Parser::NQuads;
my $qp = RDF::Trine::Parser::NQuads->new;
use RDF::Trine::Store::File::Quad;
my $store = RDF::Trine::Store::File->new_with_string( 'File;/mnt/ssdstore/data/btc-processed/hitlist-uris.nq' );
my $model = RDF::Trine::Model->new($store);
my $dct = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');


while ((my $host, my $entries) = each(%{$hosts})) {
	$progser->update(message => "Reorganizing");
	my $winningentry = ${$entries}[int(rand(scalar @{$entries}))];
	$model->add_statement(statement(iri($winningentry->{resource}), $dct->source, iri('file:///home/kjetil/Projects/SemWeb/data/btc-2014/headers/' . $winningentry->{filename})));
	$model->add_statement(statement(iri($winningentry->{resource}), $dct->type, literal('inforesources')));

}


$progser->finish;




