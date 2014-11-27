#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV;
use Data::Dumper;
use RDF::Query::Client;
use URI;

print STDERR "Reading prefix.cc URLs\n";

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

print STDERR "Querying LOV for vocabs\n";

my $query = RDF::Query::Client->new('SELECT DISTINCT ?vocabURI ?nsURI WHERE { ?vocabURI a <http://purl.org/vocommons/voaf#Vocabulary> ; <http://purl.org/vocab/vann/preferredNamespaceUri> ?nsURI . }');

my $iterator = $query->execute('http://lov.okfn.org/endpoint/lov');

while (my $row = $iterator->next) {
   my $url1 = URI->new($row->{vocabURI}->as_string);
   my $url2 = URI->new($row->{nsURI}->as_string);
	if ($hitlist{"$url2"}) {
		push(@{$hitlist{"$url2"}{'source'}}, 'lov');
	} else {
		$hitlist{"$url2"}{'source'} = ['lov'];
		$hitlist{"$url2"}{'target'} = ['vocabulary'];
	}
	my $url3 = URI->new($url1->as_string . '#');
	unless ($url2->eq($url1) || $url2->eq($url3)) {
		$hitlist{"$url2"}{'tryalso'} = "$url1";
	}
}



print Dumper(\%hitlist);
