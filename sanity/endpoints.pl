#!/usr/bin/perl
use strict;
use utf8;
use warnings;
binmode(STDOUT, ":utf8");
use Data::Dumper;
use URI::Escape;
use URI;
use Web::Scraper;

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

my $total = 0;
my $skipped = 0;
my $timedout = 0;
foreach my $row (@{$res->{rows}}) {
	next unless ($row->{'status'});
	$total++;
	warn Dumper($row);
	if ($row->{'status'}->as_string =~ m/gray/) {
		$skipped++;
		next;
	}
	my ($raw) = $row->{'link'}->as_string =~ m!^http://sparqles.okfn.org/endpoint/(\S+)$!;
	my $url = uri_unescape($raw);
	print $url . "\n";
	die "Finished" if ($total>5);
}

1;
