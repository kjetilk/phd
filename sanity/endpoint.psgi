#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Plack::Request;
use Plack::Builder;
use Config::JFDI;
use Carp qw(confess);
use RDF::Endpoint;
use LWP::MediaTypes qw(add_type);

add_type( 'application/rdf+xml' => qw(rdf xrdf rdfx) );
add_type( 'text/turtle' => qw(ttl) );
add_type( 'text/plain' => qw(nt) );
add_type( 'text/x-nquads' => qw(nq) );
add_type( 'text/json' => qw(json) );
add_type( 'text/html' => qw(html xhtml htm) );

my $config	= {
					endpoint	=> {
									 embed_images	=> 1,
									 image_width		=> 200,
									 resource_links	=> 1,
									},
					load_data	=> 1,
					update		=> 0,
				  };

$config->{store} = 'Memory;file://'.join(';file://', glob('/mnt/ssdstore/data/btc-processed/run2/crawl/*'));


my $end		= RDF::Endpoint->new( $config );

my $app	= sub {
    my $env 	= shift;
    my $req 	= Plack::Request->new($env);
    my $resp	= $end->run( $req );
	return $resp->finalize;
};

builder {
	enable "AccessLog", format => "combined";
	$app;
};

__END__
