#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use RDF::Trine;

my $dct = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');


my @files = ('/mnt/ssdstore/data/btc-processed/hitlist-test.ttl');

my $tp = RDF::Trine::Parser->new('turtle');

my $data;

my $thandler = sub {
	my $st = shift;
	my $suri = URI->new($st->subject->uri_value);
	my $host = $suri->host;
	if ($st->predicate->equal($dct->source)) {
		push(@{$data->{$host}->{$suri}->{source}}, $st->object->uri_value);
	} elsif ($st->predicate->equal($dct->type)) {
		push(@{$data->{$host}->{$suri}->{type}}, $st->object->literal_value);
	} elsif ($st->predicate->equal($dct->identifier)) {
		$data->{$host}->{$suri}->{alternate} = $st->object->uri_value;
	}
};

foreach my $filename (@files) {
	$tp->parse_file('http://invalid/', $filename, $thandler);
}

print Dumper($data);
