#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/mnt/search.slackware.eu/perl/';
use Slackware::Search::ViewSerie;
my $webapp = Slackware::Search::ViewSerie->new();
$webapp->run();
