#!/usr/bin/env perl

use strict;
use warnings;

# need to be packaged up
use Mac::Alfred::XML qw(alfred_xml_bytes);
use JSON::PP qw(decode_json);

# ship with mac
use URI;
use LWP::UserAgent;
use HTTP::Request::Common;

# setup the LWP
my $ua = LWP::UserAgent->new;
$ua->agent("alfred-metacpan/0.01");
$ua->timeout(10);
$ua->env_proxy;

# build the URL
my $uri = URI->new("http://api.metacpan.org/v0/search/autocomplete");
$uri->query_form( q => $ENV{SEARCH_QUERY} );

# get the data
my $response = $ua->get($uri);

# generate the XML
my @results = map { $_->{fields} } @{ decode_json($response->content)->{hits}{hits} };
print alfred_xml_bytes(map {+{
    title    => ($_->{documentation} || $_->{distribution}),
    subtitle => sprintf('%s (%s)', $_->{release}, $_->{author} ),
    arg      => ($_->{documentation} || $_->{distribution}),
    icon     => "icon.png"
}} @results);
