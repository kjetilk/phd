#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Progress::Any::Output;
Progress::Any::Output->set('TermProgressBarColor');
use Progress::Any;

use RDF::Trine;

my $prfetch = Progress::Any->get_indicator(
        task => "fetching");
my $prparse = Progress::Any->get_indicator(
        task => "fetching");

$prparse->update(message => "Setting up");


my $dct = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');

my $writedir = '/mnt/ssdstore/data/btc-processed/crawl/';

my @files = ('/mnt/ssdstore/data/btc-processed/hitlist-test.ttl');

my $tp = RDF::Trine::Parser->new('turtle');

my $data;

my $thandler = sub {
	my $st = shift;
	my $suri = URI->new($st->subject->uri_value);
	my $host = $suri->host;
	if ($st->predicate->equal($dct->source)) {
		push(@{$data->{$host}->{$suri}->{source}}, $st->object->uri_value);
	} elsif ($st->predicate->equal($dct->type)) {
		push(@{$data->{$host}->{$suri}->{type}}, $st->object->literal_value);
	} elsif ($st->predicate->equal($dct->identifier)) {
		$data->{$host}->{$suri}->{alternate} = $st->object->uri_value;
	}
};

foreach my $filename (@files) {
	$prparse->update(message => "Parsing $filename");
	$tp->parse_file('http://invalid/', $filename, $thandler);
}

$prparse->finish;

$prfetch->update(message => "Initializing UA");

use Parallel::ForkManager;
my $pm = Parallel::ForkManager->new(4);

use LWP::UserAgent;
use HTTP::Request;

my $ua = LWP::UserAgent->new;
$ua->agent('Semweb cache project (see http://folk.uio.no/kjekje/ ) ');
$ua->max_size( 1000000 );
$ua->timeout( 20 );

my @hosts = keys %{$data};
$prfetch->target(scalar @hosts);

DATA_LOOP:
foreach my $host (@hosts) {
  my $uricount = scalar keys %{$data->{$host}};
  $prfetch->update(message => "Fetching $uricount resources from $host");
  # Forks and returns the pid for the child:
  my $pid = $pm->start and next DATA_LOOP;
  open (my $fh, '>>', $writedir . $host) || die "Couldn't open $writedir for writing";
  while ((my $uri, my $details) = each(%{$data->{$host}})) {
	  my $request = HTTP::Request->new(GET => $uri);
	  if ($details->{type} eq 'endpoint') {
		  $request->uri( $uri . 'SELECT DISTINCT * WHERE {	?s a ?class . } LIMIT 10');
		  $request->header( Accept => '*/*' );
	  } else {
		  $request->header( Accept => RDF::Trine::Parser::default_accept_header );
	  }
	  my $firstresponse = $ua->request( $request );
	  if ($firstresponse->is_success) {
		  my $etag = $firstresponse->header('ETag');
		  print $fh $uri . "\t" . $etag . "\n" if ($etag);
	  }
	  sleep 5 if ($uricount > 1);
  }
  close $fh;
  $pm->finish; # Terminates the child process
}

$prfetch->finish;
