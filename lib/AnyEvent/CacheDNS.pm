package AnyEvent::CacheDNS;

use strict;
use warnings;
use base 'AnyEvent::DNS';

use Data::Dumper;

our $VERSION = '0.02';

sub import {
	my $package = shift;
	my @options = @_;
	
	while (@options) {
		my $key = shift @options;
		if ($key eq ':register') {
			$package->register();
		}
	}
}


sub resolve {
	my $cb = pop @_;
	my ($self, $qname, $qtype, %opt) = @_;

	# If we have the value cached then we serve it from there
	my $cache = $self->{_cache}{$qtype} ||= {};
	if (exists $cache->{$qname}) {
		my $response = $cache->{$qname};
		$cb->($response ? ($response) : ());
		return;
	}

	# Performe a request and cache the value
	$self->SUPER::resolve(
		$qname,
		$qtype,
		%opt,
		sub{
			# Note that it could be possible that the multiple DNS request are
			# done a new qname. For instance if an application is doing multiple
			# concurrent HTTP request to the same host then there will be at
			# least one DNS request per HTTP request. That's why we only cache
			# the results of the first DNS request that's successful.
			$cache->{$qname} ||= @_ ? $_[0] : undef;
			$cb->(@_);
		}
	);
}


sub register {
	my $class = shift;
	$AnyEvent::DNS::RESOLVER = $class->new();
}


1;

=head1 NAME

AnyEvent::CacheDNS - Simple DNS resolver with caching

=head1 SYNOPSIS

	use AnyEvent::Impl::Perl;
	use AnyEvent;
	use AnyEvent::HTTP;
	
	# Register our DNS resolver as the default resolver
	use AnyEvent::CacheDNS ':register';
	
	# Use AnyEvent as ususal
	my $cond = AnyEvent->condvar;
	http_get "http://search.cpan.org/", sub { $cond->send(); };
	$cond->recv();

=head1 DESCRIPTION

This module provides a very simple DNS resolver that caches its results and can
improve the connection times to remote hosts.

=head1 Import

It's possible to register the this class as AnyEvent's main DNS resolver by
passing the tag C<:register> in the C<use> statement.

=head1 METHODS

=head2 register

Registers a new DNS cache instance as AnyEvent's global DNS resolver.

=head1 AUTHOR

Emmanuel Rodriguez <potyl@cpan.org>

=head1 COPYRIGHT

(C) 2011 Emmanuel Rodriguez - All Rights Reserved.

=cut
