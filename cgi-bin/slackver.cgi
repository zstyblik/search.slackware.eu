#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/mnt/search.slackware.eu/perl/';
use Slackware::Search::ViewSlackver;
my $webapp = Slackware::Search::ViewSlackver->new();
$webapp->run();
