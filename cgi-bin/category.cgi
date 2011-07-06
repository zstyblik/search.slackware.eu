#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/mnt/search.slackware.eu/perl/';
use Slackware::Search::ViewCategory;
my $webapp = Slackware::Search::ViewCategory->new();
$webapp->run();
