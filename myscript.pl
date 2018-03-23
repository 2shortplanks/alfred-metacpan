#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP qw(encode_json decode_json);
use LWP::UserAgent;

# The default install of Perl doesn't have any certificate files shipped with
# it.  Given the option of being insecure against man-in-the-middle attacks
# or requiring a dependency, we take the insecure route
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

# setup the LWP
my $ua = LWP::UserAgent->new;
$ua->agent("alfred-metacpan/2.00");
$ua->timeout(10);
$ua->env_proxy;

# build the URL
my $uri = URI->new("https://metacpan.org/search/autocomplete");
$uri->query_form( q => shift(@ARGV) );

# get the data
my $response = $ua->get($uri);
my $data = decode_json($response->content)->{suggestions};

my @items;
for my $item (@{ $data }) {
  my $type = $item->{data}{type};

  if ($type eq 'module') {
    my $name = $item->{data}{module};
    my $url = "https://metacpan.org/pod/$name";
    push @items, {
      uid => $url,
      title => $name,
      arg => $url,
      icon => { path => 'icons/data-management-interface-symbol-with-gears-and-binary-code-numbers.png' },
    };
    next;
  }

  if ($type eq 'author') {
    my $name = $item->{data}{id};
    my $url = "https://metacpan.org/author/$name";
    push @items, {
      uid => $url,
      title => $item->{value},
      arg => $url,
      icon => { path => 'icons/binary-thinking.png' },
    };
    next;
  }

  # ignore this item?
}

unless (@items) {
  push @items, {
    valid => 0,
    title => "No Matches",
    icon => { path => 'icons/question-mark-button.png' },
  }
}

print encode_json({ items => \@items });
