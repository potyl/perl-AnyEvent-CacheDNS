#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::CacheDNS ':register';
use AnyEvent::DNS;
use Data::Dumper;


sub main {

	# Make sure we timeout faster
	my $dns = AnyEvent::DNS::resolver;
	isa_ok($dns, 'AnyEvent::CacheDNS');

	$dns->{timeout} = [0.5];
	$dns->_compile();

	my $cv;

	$cv = AnyEvent->condvar;
	$dns->resolve("www.google.sk", 'a', sub { $cv->send(@_) });
	my ($first) = $cv->recv();
	ok($first, "First DNS lookup");

	$cv = AnyEvent->condvar;
	$dns->resolve("www.google.sk", 'a', sub { $cv->send(@_) });
	my ($second) = $cv->recv();
	ok($second, "Second DNS lookup");
	is_deeply($first, $second, "DNS records identical");
	ok($first == $second, "DNS records same ref");

	ok(keys %{ $dns->{_cache} } == 1, "DNS cache was used");

	return 0;
}



exit main() unless caller;
