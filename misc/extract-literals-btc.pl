#!/usr/bin/perl

use strict;
use warnings;

use PerlIO::gzip;

open (COMQ, "<:gzip", $ARGV[0]);
while (<COMQ>) {
	my ($lit) = m/\"(.+)\"/;
	print "$lit\n" if ($lit);
}

binmode COMQ, ":gzip(none)";
