#!/usr/bin/perl
use strict;
use utf8;
use warnings;
binmode(STDOUT, ":utf8");
use Data::Dumper;
use URI::Escape;
use URI;
use Web::Scraper;
use LWP::UserAgent;


my $rows = scraper {
  process "tr", "rows[]" => scraper {
    process "td > img" , status => '@src';
    process "td + td > a" , link => '@href';
    process "td + td" , title => 'TEXT';

  };
};

#my $res = $rows->scrape( URI->new("http://sparqles.okfn.org/availability") );
my $res = $rows->scrape( URI->new("file:///home/kjetil/Projects/SemWeb/PhD/sanity/SPARQL\ Endpoints\ Status.html") );

#die Dumper($res);
use RDF::Trine qw(statement iri literal);

use RDF::Trine::Store::File::Quad;
my $store = RDF::Trine::Store::File::Quad->new_with_string( 'File::Quad;/mnt/ssdstore/data/btc-processed/hitlist-sparqles.nq' );
my $dct = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');

my $om = RDF::Trine::Model->new($store);
foreach my $row (@{$res->{rows}}) {
	next unless ($row->{'status'});
	if ($row->{'status'}->as_string =~ m/gray/) {
		next;
	}
	my ($raw) = $row->{'link'}->as_string =~ m!^http://sparqles.okfn.org/endpoint/(\S+)$!;
	my $url = iri(uri_unescape($raw));
	$om->add_statement(statement($url, $dct->source, iri('http://sparqles.okfn.org/')));
	$om->add_statement(statement($url, $dct->type, literal('endpoint')));
}

1;
