#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use AnyEvent;
use AnyEvent::CacheDNS ':register';
use AnyEvent::DNS;
use Data::Dumper;


sub main {

	# Make sure we timeout fast
	my $dns = AnyEvent::DNS::resolver;
	isa_ok($dns, 'AnyEvent::CacheDNS');
	$dns->{timeout} = [0.5];
	$dns->_compile();

	my $cv;

	my $host = "www.bratislavafestival.sk";
	$cv = AnyEvent->condvar;
	$dns->resolve($host, 'a', $cv);
	my ($first) = $cv->recv();
	ok($first, "First DNS lookup");

	$cv = AnyEvent->condvar;
	$dns->resolve($host, 'a', $cv);
	my ($second) = $cv->recv();
	ok($second, "Second DNS lookup");

	is_deeply($first, $second, "DNS records identical");
	ok($first == $second, "DNS records same ref");

	# Inspect the cache
	ok(keys %{ $dns->{_cache} } == 1, "DNS cache was used");
	ok(keys %{ $dns->{_cache}{a} } == 1, "DNS cache has a sinle host");

	my @cached = @{ $dns->{_cache}{a}{$host} };
	ok(pop @cached, "IP address is true");
	is_deeply(\@cached, [$host, 'a', 'in'], "DNS response matches");

	return 0;
}



exit main() unless caller;
