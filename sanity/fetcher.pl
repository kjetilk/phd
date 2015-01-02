#!/usr/bin/perl

# Rev 877 is first attempt to prod
# Rev 922 is analysis run
use strict;
use warnings;
use Data::Dumper;
use Progress::Any::Output;
Progress::Any::Output->set('TermProgressBarColor');
use Progress::Any;

use RDF::Trine qw(iri statement literal);
use RDF::Trine::Store::File::Quad;
use RDF::Generator::HTTP 0.003;

my $prfetch = Progress::Any->get_indicator(
        task => "fetching");
my $prparse = Progress::Any->get_indicator(
        task => "parsing");

$prparse->update(message => "Setting up");


my $dct = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');

#my $basedir = '/home/kjetil/data/sanity/';
my $basedir = '/mnt/ssdstore/data/btc-processed/';

my $writedir = $basedir . 'crawl/';

#my @files = ($basedir . 'hitlist-test.ttl');
my @files = ($basedir . 'hitlist-data.ttl', $basedir . 'hitlist-uris.nq', $basedir . 'hitlist-sparqles.nq');


my $tp = RDF::Trine::Parser->new('turtle');

my $data;

my %typepref = ( endpoint => 3, vocabulary => 2, dataset => 1, inforesources => 0 );

my $thandler = sub {
	my $st = shift;
	my $suri = URI->new($st->subject->uri_value);
	my $host = $suri->host;
	if ($st->predicate->equal($dct->source)) {
		push(@{$data->{$host}->{$suri}->{source}}, $st->object->uri_value);
	} elsif ($st->predicate->equal($dct->type)) {
		if ($data->{$host}->{$suri}->{type}) {
			# Precedence: endpoint > vocabulary > dataset > inforesources
			# For this purpose, datasets are just inforesources
			if ($typepref{$st->object->literal_value} > $typepref{$data->{$host}->{$suri}->{type}}) {
				$data->{$host}->{$suri}->{type} = $st->object->literal_value;
			}
		} else {
			$data->{$host}->{$suri}->{type} = $st->object->literal_value;
		}
	} elsif ($st->predicate->equal($dct->identifier)) {
		$data->{$host}->{$suri}->{alternate} = $st->object->uri_value;
	}
};

foreach my $filename (@files) {
	$prparse->update(message => "Parsing $filename");
	$tp->parse_file('http://invalid/', $filename, $thandler);
}

my $qhandler = sub {
	my $st = shift;
	my $suri = URI->new($st->graph->uri_value);
	my $host = $suri->host;
	unless ($data->{$host}->{$suri}) {
		$data->{$host}->{$suri}->{type} = 'inforesources';
	}
	push(@{$data->{$host}->{$suri}->{source}}, 'file:///home/kjetil/Projects/SemWeb/data/btc-2014/headers/');
	if ($st->predicate->equal(iri('http://www.w3.org/2006/http#expires'))) {
		$data->{$host}->{$suri}->{expires} = $st->object->literal_value;
	}
	if ($st->predicate->equal(iri('http://www.w3.org/2006/http#etag'))) {
		$data->{$host}->{$suri}->{etag} = $st->object->literal_value;
	}
	if ($st->predicate->equal(iri('http://www.w3.org/2006/http#last-modified'))) {
		$data->{$host}->{$suri}->{mtime} = $st->object->literal_value;
	}
};

my $filename=$basedir . 'hitlist-headers.nq';
my $qp = RDF::Trine::Parser->new('nquads');
$prparse->update(message => "Parsing $filename");
$qp->parse_file('http://invalid/', $filename, $qhandler);

$prparse->finish;

$prfetch->update(message => "Initializing UA");

use Parallel::ForkManager;
my $pm = Parallel::ForkManager->new(50);

use LWP::UserAgent;
use HTTP::Request;
use URI::Escape::XS qw/uri_escape/;
use DateTime;
use DateTime::Format::Mail;
use Try::Tiny;
use RDF::Trine::Iterator;

my $ua = LWP::UserAgent->new;
$ua->agent('Semweb cache project (see http://folk.uio.no/kjekje/ ) ');
$ua->max_size( 1000000 );
$ua->timeout( 20 );

my $accept_header = RDF::Trine::Parser::default_accept_header;

$accept_header =~ s|application/xhtml\+xml;q=0.9,||;
$accept_header =~ s|application/json;q=0.9,||;
$accept_header =~ s|text/plain;q=0.9,||;
$accept_header =~ s|application/octet-stream;q=0.9,||;
$accept_header =~ s|,text/html;q=0.9||;

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
	  my $context = iri($uri);
	  my $promise = '';
	  foreach my $source (@{$details->{source}}) {
		  $model->add_statement(statement(iri($uri), $dct->source, iri($source), $context));
	  }
	  $model->add_statement(statement(iri($uri), $dct->type, literal($details->{type}), $context));
	  if ($details->{expires}) {
		  my $oldtime = DateTime::Format::Mail->parse_datetime($details->{expires});
		  if (DateTime->compare( $oldtime, DateTime->now ) >= 0) {
			  $model->add_statement(statement(iri($uri), iri('urn:app:stillfresh'), literal($details->{expires}), $context));
		  }
	  }

	  my $request = HTTP::Request->new(GET => $uri);
	  if ($details->{type} eq 'endpoint') {
		  $uri .= '?query=' . uri_escape('select reduced ?Concept where {[] a ?Concept} LIMIT 2');
		  $request->uri( $uri );
		  $request->header( Accept => 'application/sparql-results+xml,application/sparql-results+json;q=0.9' );
	  } else {
		  $request->header( Accept => $accept_header );
		  if ($details->{mtime}) {
			  $request->header( 'If-Modified-Since' => $details->{mtime} );
		  }
		  if ($details->{etag}) {
			  $request->header( 'If-None-Match' => $details->{etag} );
		  }
	  }
	  my $firstresponse = $ua->request( $request );
	  $model->add_statement(statement(iri($uri), iri('urn:app:whichrequest'), literal('firstresponse'), $context));
		  # Get the relevant headers
	  my $hhg = RDF::Generator::HTTP->new(message => $firstresponse,
													  whitelist => ['Age',
																		 'Server',
																		 'Cache-Control',
																		 'Expires',
																		 'Pragma',
																		 'Warning',
																		 'Content-Type',
																		 'If-None-Match',
																		 'If-Modified-Since',
																		 'Last-Modified',
																		 'ETag',
																		 'X-Cache',
																		 'Date',
																		 'Surrogates',
																		 'Client-Aborted',
																		 'Client-Warning'
																		],
													  graph => $context);
	  $hhg->generate($model);
	  $model->add_statement(statement(iri($uri), iri('urn:app:hasrequest'), $hhg->request_subject, $context));

	  my $prevresponse = $firstresponse;

	  # What to do if data for conditional requests was available in BTC
	  if ($firstresponse->code == 304) {
		  my $condrequest = HTTP::Request->new(GET => $uri);
		  sleep 5;
		  my $condresponse = $ua->request( $condrequest );
		  $model->add_statement(statement(iri($uri), iri('urn:app:whichrequest'), literal('condresponse'), $context));
		  my $condhhg = RDF::Generator::HTTP->new(message => $condresponse,
																whitelist => ['Warning',
																				  'Server',
																				  'Last-Modified',
																				  'ETag',
																				  'Date'],
																graph => $context);
		  $condhhg->generate($model);
		  $model->add_statement(statement(iri($uri), iri('urn:app:hasrequest'), $condhhg->request_subject, $context));
		  if ($condresponse->is_success) {
			  $model->add_statement(statement(iri($uri), iri('urn:app:status'), literal('OK'), $context));
		  } else {
			  $model->add_statement(statement(iri($uri), iri('urn:app:status'), literal('Second conditional failed'), $context));
		  }

		  $prevresponse = $condresponse;

	  } elsif ($firstresponse->is_success) {

		  # Add freshness triples
		  if ($prevresponse->freshness_lifetime(heuristic_expiry => 0)) {
			  $model->add_statement(statement(iri($uri), iri('urn:app:freshtime:hard'), literal($prevresponse->freshness_lifetime(heuristic_expiry => 0)), $context));
			  $promise = 'hard';
		  } elsif ($prevresponse->headers->last_modified) {
			  $model->add_statement(statement(iri($uri), iri('urn:app:freshtime:heuristic'), literal($prevresponse->freshness_lifetime(h_min => 1, h_max => 31536001, h_default =>0)), $context));
			  $promise = 'heuristic';
		  }

		  my $content = $prevresponse->decoded_content;

		  # Now, if there were conditional headers, we try again to see if it is really supported
		  my $ya = 0;
		  my $cond2request = HTTP::Request->new(GET => $uri);
		  if ($prevresponse->header('Last-Modified')) {
			  $ya = 1;
			  $cond2request->header( 'If-Modified-Since' => $prevresponse->header('Last-Modified') );
		  }
		  if ($prevresponse->header('ETag')) {
			  $ya = 1;
			  $cond2request->header( 'If-None-Match' => $prevresponse->header('ETag') );
		  }
		  if ($ya) {
			  no warnings 'uninitialized';
			  sleep 10;
			  my $cond2response = $ua->request( $cond2request );
			  $model->add_statement(statement(iri($uri), iri('urn:app:whichrequest'), literal('cond2response'), $context));
			  my $cond2hhg = RDF::Generator::HTTP->new(message => $cond2response,
																	 whitelist => ['Warning',
																						'Server',
																						'If-None-Match',
																						'If-Modified-Since',
																						'Last-Modified',
																						'ETag',
																						'Date'],
																	 graph => $context);
			  $cond2hhg->generate($model);
			  $model->add_statement(statement(iri($uri), iri('urn:app:hasrequest'), $cond2hhg->request_subject, $context));
			  if (($cond2response->code == 200) &&
					($prevresponse->header('ETag') eq $cond2response->header('ETag')) &&
					($prevresponse->header('Last-Modified') eq $cond2response->header('Last-Modified'))) {
				  # We should have gotten 304
				  $model->add_statement(statement(iri($uri), iri('urn:app:conditional'), literal("Got all"), $context));
			  } else {
				  $promise = 'not-modified';
			  }
		  }
		  my @endpoints;

		  if ($details->{type} eq 'endpoint') {
			  # Check if we got any results
			  my $anyres = has_sparql_results($content, $prevresponse->content_type) ? "Has results" : "No results";
			  $model->add_statement(statement(iri($uri), iri('urn:app:endpoint'), literal($anyres), $context));
		  } else { # All RDF resources
			  my $parsertype = RDF::Trine::Parser->parser_by_media_type($prevresponse->content_type);
			  if ($parsertype) {
				  my $parser = $parsertype->new;
				  # Then it is likely we get RDF
				  my $size = 0;
				  my $parseerror;

				  try {
					  no warnings;
					  $parser->parse('http://invalid/', $content, 
										  sub {
											  my $st = shift;
											  $size++;
											  # Look for dct dates
											  if ($st->predicate->equal($dct->date) ||
													$st->predicate->equal($dct->accrualPeriodicity) ||
													$st->predicate->equal($dct->created) ||
													$st->predicate->equal($dct->issued) ||
													$st->predicate->equal($dct->modified) ||
													$st->predicate->equal($dct->valid)) {
												  $model->add_statement(statement($st->subject, $st->predicate, $st->object, $context));
												  $promise = 'predicate';
											  } elsif ($st->predicate->equal(iri('http://www.w3.org/ns/sparql-service-description#endpoint')) ||
														  $st->predicate->equal(iri(('http://rdfs.org/ns/void#sparqlEndpoint')))) {
												  push(@endpoints, $st->object->uri_value);
											  }
										  });
				  } catch {
					  $model->add_statement(statement(iri($uri), iri('urn:app:parseerror'), literal($_), $context));
					  $parseerror = 1;
				  };

				  unless ($details->{type} eq 'vocabulary') {
					  # Look for endpoints, if so, do as in endpoint
					  foreach my $endpoint (@endpoints) {
						  my $euri = URI->new($endpoint);
						  unless ($data->{$euri->host}->{$endpoint}) {
							  $uri = $endpoint . '?query=' . uri_escape('select reduced ?Concept where {[] a ?Concept} LIMIT 2');	  
							  my $erequest = HTTP::Request->new(GET => $uri);
							  $erequest->header( Accept => 'application/sparql-results+xml,application/sparql-results+json;q=0.9' );
							  my $eresponse = $ua->request( $erequest );
							  $model->add_statement(statement(iri($uri), iri('urn:app:whichrequest'), literal('eresponse'), $context));
							  # Get the relevant headers
							  my $ehhg = RDF::Generator::HTTP->new(message => $eresponse,
																				whitelist => ['Age',
																								  'Server',
																								  'Cache-Control',
																								  'Expires',
																								  'Pragma',
																								  'Warning',
																								  'Content-Type',
																								  'Last-Modified',
																								  'ETag',
																								  'X-Cache',
																								  'Date',
																								  'Surrogates',
																								  'Client-Aborted',
																								  'Client-Warning'
																								 ],
																				graph => iri($endpoint));
							  $ehhg->generate($model);
							  $model->add_statement(statement(iri($uri), iri('urn:app:hasrequest'), $ehhg->request_subject, $context));
							  if ($eresponse->is_success) {
								  my $anyres = has_sparql_results($eresponse->decoded_content, $eresponse->content_type) ? "Has results" : "No results";
								  $model->add_statement(statement(iri($uri), iri('urn:app:endpoint'), literal($anyres), iri($endpoint)));
								  $model->add_statement(statement(iri($uri), iri('urn:app:status'), literal('OK'), $context));

								  # Add freshness triples
								  if ($eresponse->freshness_lifetime(heuristic_expiry => 0)) {
									  $model->add_statement(statement(iri($uri), iri('urn:app:freshtime:hard'), literal($eresponse->freshness_lifetime(heuristic_expiry => 0)), $context));
									  $promise = 'hard';
								  } elsif ($eresponse->headers->last_modified) {
									  $model->add_statement(statement(iri($uri), iri('urn:app:freshtime:heuristic'), literal($eresponse->freshness_lifetime(h_min => 1, h_max => 31536001, h_default =>0)), $context));
									  $promise = 'heuristic';
								  }

							  }
						  }
					  }
				  }

				  if ($parseerror) {
					  $model->add_statement(statement(iri($uri), iri('urn:app:status'), literal('parseerror'), $context));
				  } else {
					  $model->add_statement(statement(iri($uri), iri('urn:app:status'), literal('OK'), $context));
				  }
			  } else {
				  $model->add_statement(statement(iri($uri), iri('urn:app:status'), literal('Invalid media type'), $context));
			  }
		  }
	  } else {
		  $model->add_statement(statement(iri($uri), iri('http://www.w3.org/2007/ont/http#status_line'), literal($prevresponse->status_line), $context));
		  $model->add_statement(statement(iri($uri), iri('urn:app:status'), literal('Unsuccessful response'), $context));
		  if ($details->{alternate}) {
			  my $aresponse = $ua->get($details->{alternate}, Accept => $accept_header);
			  my $alturi = iri($details->{alternate});
			  $model->add_statement(statement($alturi, iri('urn:app:whichrequest'), literal('aresponse'), $context));
			  # Get the relevant headers
			  my $ahhg = RDF::Generator::HTTP->new(message => $aresponse,
																whitelist => ['Age',
																				  'Server',
																				  'Cache-Control',
																				  'Expires',
																				  'Pragma',
																				  'Warning',
																				  'Content-Type',
																				  'Last-Modified',
																				  'ETag',
																				  'X-Cache',
																				  'Date',
																				  'Surrogates',
																				  'Client-Aborted',
																				  'Client-Warning'
																				 ],
																graph => $context);
			  $ahhg->generate($model);
			  $model->add_statement(statement($alturi, iri('urn:app:hasrequest'), $ahhg->request_subject, $context));
			  if ($aresponse->is_success) {
				  $model->add_statement(statement($alturi, iri('urn:app:status'), literal('OK'), $context));

				  # Add freshness triples
				  if ($aresponse->freshness_lifetime(heuristic_expiry => 0)) {
					  $model->add_statement(statement($alturi, iri('urn:app:freshtime:hard'), literal($aresponse->freshness_lifetime(heuristic_expiry => 0)), $context));
					  $promise = 'hard';
				  } elsif ($aresponse->headers->last_modified) {
					  $model->add_statement(statement($alturi, iri('urn:app:freshtime:heuristic'), literal($aresponse->freshness_lifetime(h_min => 1, h_max => 31536001, h_default =>0)), $context));
					  $promise = 'heuristic';
				  }
			  } else {
				  $model->add_statement(statement($alturi, iri('urn:app:status'), literal('Alternate failed'), $context));
			  }
		  }
	  }
	  if ($promise) {
		  $model->add_statement(statement(iri($uri), iri('urn:app:promising'), literal($promise), $context));
	  }
	  sleep 10 if ($uricount > 1);
  }
  $pm->finish; # Terminates the child process
}


sub has_sparql_results {
	my ($content, $ct) = @_;
	my $iter = try {
		if ($ct =~ /json/) { 
			RDF::Trine::Iterator->from_json($content); 
		} else { 
			RDF::Trine::Iterator->from_string($content); 
		}
	} catch {
		return 0;
	};
	return 1 if ($iter->next);
	return 0;
}


$prfetch->finish;
