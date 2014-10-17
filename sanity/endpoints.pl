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

my %counts = (total => 0, 
				  skipped => 0, 
				  failed => 0,
				  expires => 0,
				  control => 0
				 );

my $query = "select reduced ?Concept where {[] a ?Concept} LIMIT 2";

foreach my $row (@{$res->{rows}}) {
	next unless ($row->{'status'});
	$counts{total}++;
#	warn Dumper($row);
	if ($row->{'status'}->as_string =~ m/gray/) {
		$counts{skipped}++;
		next;
	}
	my ($raw) = $row->{'link'}->as_string =~ m!^http://sparqles.okfn.org/endpoint/(\S+)$!;
	my $url = uri_unescape($raw);
	print STDERR $url . "\t";
	my $ua = LWP::UserAgent->new;
	$ua->timeout(30);
	my $response = $ua->get($url . '?query=' . uri_escape_utf8($query));
	if ($response->is_success) {
		#warn $response->content;
		if ($response->header('Expires')) {
			print STDERR $response->header('Expires') . "\t";
			$counts{expires}++;
		}
		if ($response->header('Cache-Control')) {
			print STDERR $response->header('Cache-Control') . "\t";
			$counts{control}++;
		}
	} else {
		$counts{failed}++;
	}
	print STDERR "\n";
}

print Dumper(\%counts);

1;
