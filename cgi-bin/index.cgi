#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/mnt/search.slackware.eu/perl/';
use Slackware::Search::Indexor;
my $webapp = Slackware::Search::Indexor->new();
$webapp->run();
