#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use RDF::Trine;

my $dct = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');


my @files = ('/mnt/ssdstore/data/btc-processed/hitlist-test.ttl');

my $tp = RDF::Trine::Parser->new('turtle');

my $data;
foreach my $filename (@files) {
	$tp->parse_file('', $filename, \&thandler);
}

my $thandler = sub {
	my $st = shift;
	my $suri = URI->new($st->subject->uri_value);
	my $host = $suri->host;
	if ($st->predicate->equals($dct->source)) {
		push(@{$data->{$host}->{$suri}->{source}}, $st->object->uri_value);
	} elsif ($st->predicate->equals($dct->type)) {
		push(@{$data->{$host}->{$suri}->{type}}, $st->object->literal_value);
	} elsif ($st->predicate->equals($dct->identifier)) {
		$data->{$host}->{$suri}->{alternate} = $st->object->uri_value;
	}
}

print Dumper($data);
