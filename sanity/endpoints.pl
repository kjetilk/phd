#!/usr/bin/perl
use strict;
use utf8;
use warnings;
binmode(STDOUT, ":utf8");
use Data::Dumper;

use URI;
use Web::Scraper;
my $rows = scraper {
  process "tr", "rows[]" => scraper {
    process "td > img" , status => '@src';
    process "td + td > a" , link => '@href';
    process "td + td" , title => 'TEXT';

  };
};

my $res = $rows->scrape( URI->new("http://sparqles.okfn.org/availability") );

my $i = 0;
foreach my $row (@{$res->{rows}}) {
	$i++;
	warn Dumper($row);
die "Finished" if ($i>5);
}

1;
