#!/usr/bin/perl

use strict;
use warnings;

use PerlIO::gzip;

open (COMQ, "<:gzip", $ARGV[0]);
print STDERR "Extracting literals from $ARGV[0]\n";
while (<COMQ>) {
	my ($lit) = m/\"(.+)\"/;
	print "$lit\n" if ($lit);
}

binmode COMQ, ":gzip(none)";
