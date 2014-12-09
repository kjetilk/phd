#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Progress::Any::Output;
Progress::Any::Output->set('TermProgressBarColor');
use Progress::Any;

use RDF::Trine qw(iri);
use RDF::Trine::Store::File::Quad;
use RDF::Generator::HTTP;

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
use URI::Escape::XS qw/uri_escape/;

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
  my $store = RDF::Trine::Store::File::Quad->new_with_string( "File::Quad;$writedir$host.nq" );
  my $model = RDF::Trine::Model->new($store);
  while ((my $uri, my $details) = each(%{$data->{$host}})) {
	  my $request = HTTP::Request->new(GET => $uri);
	  if ($details->{type} eq 'endpoint') {
		  $uri .= '?query=' . uri_escape('select reduced ?Concept where {[] a ?Concept} LIMIT 2');
		  $request->uri( $uri );
		  $request->header( Accept => '*/*' );
	  } elsif ($details->{type} eq 'conditionals') {
		  $request->header( Accept => RDF::Trine::Parser::default_accept_header );
#		  $request->header( 'If-Modified-Since' =>  ); TODO
#		  $request->header( 'If-None-Matches' =>  );
	  } else {
		  $request->header( Accept => RDF::Trine::Parser::default_accept_header );
	  }
	  my $firstresponse = $ua->request( $request );
	  if ($firstresponse->is_success) {
		  # Get the relevant headers
		  my $hhg = RDF::Generator::HTTP->new(message => $firstresponse,
														  whitelist => ['Age',
																			 'Cache-Control',
																			 'Expires',
																			 'Pragma',
																			 'Warning',
																			 'Last-Modified',
																			 'ETag',
																			 'X-Cache',
																			 'Date',
																			 'Surrogates'],
														  graph => iri($uri));
		  $hhg->generate($model);

		  # If conditional, try them
		  if ($firstresponse->headers->header('ETag') || $firstresponse->headers->header('Last-Modified')) {
			  my $condrequest = HTTP::Request->new(GET => $uri);
			  if ($firstresponse->headers->header('Last-Modified')) {
				  $condrequest->header( 'If-Modified-Since' => $firstresponse->headers->header('Last-Modified'));
			  }
			  if ($firstresponse->headers->header('ETag')) {
				  $condrequest->header( 'If-None-Match' => $firstresponse->headers->header('ETag'));
			  }
			  sleep 5;
			  my $condresponse = $ua->request( $condrequest );
			  my $condhhg = RDF::Generator::HTTP->new(message => $condresponse,
																	whitelist => ['Warning',
																					  'If-None-Match',
																					  'If-Modified-Since',
																					  'Last-Modified',
																					  'ETag',
																					  'Date'],
																	graph => iri($uri));
			  $condhhg->generate($model);
		  }

		  if ($details->{type} eq 'endpoint') {
			  # TODO
			  # Check if we got any results
		  } elsif ($details->{type} eq 'dataset') {
			  # TODO
			  # Look for dct dates
			  # Look for endpoints, if so, do as in endpoint
			  # Look for vocabularies, if so, do as in vocabulary
		  } elsif ($details->{type} eq 'vocabulary') {
			  # TODO
			  # Look for dct dates
		  } elsif ($details->{type} eq 'inforesources') {
			  # TODO
			  # Look for dct dates
			  # Look for endpoints, if so, do as in endpoint
			  # Look for vocabularies, if so, do as in vocabulary
		  } elsif ($details->{type} eq 'conditionals') {
			  # TODO
			  # Check if still fresh
			  # Get the relevant headers
			  # If 304, try without
			  # Get the relevant headers
			  # Look for dct dates
			  # Look for endpoints, if so, do as in endpoint
			  # Look for vocabularies, if so, do as in vocabulary
		  }
	  } else {
		  # TODO: Examine the failure and record
	  }
	  sleep 5 if ($uricount > 1);
  }
  $pm->finish; # Terminates the child process
}

$prfetch->finish;
