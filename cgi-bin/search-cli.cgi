#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/mnt/search.slackware.eu/perl/';
use Slackware::Search::FinderCLI;
my $webapp = Slackware::Search::FinderCLI->new();
$webapp->run();
