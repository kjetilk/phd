#!/usr/bin/perl

use strict;
use warnings;

use URI;
use Data::Dumper;
use Progress::Any::Output;
Progress::Any::Output->set('TermProgressBarColor');
use Progress::Any;   

my $progress = Progress::Any->get_indicator(
        task => "scanning");

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
	push(@{$hosts->{$resource->host}}, \%entry);
}
close $fh;

$progress->target($pos + 10000 + (scalar keys %{$hosts}) * 400);
my $files;
while ((my $host, my $entries) = each(%{$hosts})) {
	$progress->update(message => "Reorganizing");
	my $winningentry = ${$entries}[int(rand(scalar @{$entries}))];
	$files->{$winningentry->{filename}}->{$winningentry->{resource}} = 1;
}

$progress->update(message => "Preparing file to write to");

$hosts = undef;

use RDF::Trine qw(iri);
use RDF::Trine::Parser::NQuads;
my $qp = RDF::Trine::Parser::NQuads->new;
use RDF::Trine::Store::File::Quad;
my $store = RDF::Trine::Store::File::Quad->new_with_string( 'File::Quad;/mnt/ssdstore/data/btc-processed/hitlist-headers.nq' );
my $model = RDF::Trine::Model->new($store);
my $httpo = RDF::Trine::Namespace->new('http://www.w3.org/2006/http#');
my $urllist;

$progress->update(message => "Starting parsing");

my $prevurl = '';

sub handler {
	my $st = shift;
	next FILE if scalar keys(%{$urllist}) < 1;
	if($urllist->{$st->graph->uri_value}) {
		if($st->predicate->equal($httpo->expires) ||
 			$st->predicate->equal($httpo->etag) ||
 			$st->predicate->equal(iri("$httpo" . 'last-modified'))) {
			$model->add_statement($st);
 		}
		unless ($st->graph->uri_value eq $prevurl) {
			delete $urllist->{$prevurl};
			$prevurl = $st->graph->uri_value;
		}

	}
}


FILE: while ((my $filename, $urllist) = each(%{$files})) {
	my $count = scalar keys %{$urllist};
	$pos+=$count*400;
	$progress->update(message => "Parsing $filename, adding $count URLs", pos => $pos);

	$qp->parse_file('', '/home/kjetil/Projects/SemWeb/data/btc-2014/headers/' . $filename, \&handler);
}

$progress->finish;




