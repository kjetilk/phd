#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;
use Data::Dumper;

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
                or die "Cannot use CSV: ".Text::CSV->error_diag ();

my %hitlist;
open my $fh, "<:encoding(utf8)", "/home/kjetil/Projects/SemWeb/data/all.file.csv" or die "all.file.csv: $!";
while ( my $row = $csv->getline( $fh ) ) {
	my $url = $row->[1];
	$hitlist{$url}{'source'} = ['prefix.cc'];
	$hitlist{$url}{'target'} = ['vocabulary'];
}

$csv->eof or $csv->error_diag();
close $fh;

print Dumper(\%hitlist);
