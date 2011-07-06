#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/mnt/search.slackware.eu/perl/';
use Slackware::Search::ViewPackage;
my $webapp = Slackware::Search::ViewPackage->new();
$webapp->run();
