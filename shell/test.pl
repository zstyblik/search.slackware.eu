#!/usr/bin/perl
use strict;
use warnings;

my $word = 'word #free (bongo) tome!';
my @wordArr = split(//, $word);
while (my $char = shift(@wordArr)) {
	next if ($char !~ /[A-Za-z0-9\ ]+/);
	printf("%s\n", $char);
}
