#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/mnt/search.slackware.eu/perl/';
use Slackware::Search::Finder;
my $webapp = Slackware::Search::Finder->new();
$webapp->run();
