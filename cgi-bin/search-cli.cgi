#!/usr/bin/perl -wT
use strict;
use CGI::Carp qw(fatalsToBrowser);
use lib '/home/search.slackware.eu/perl/';
use Slackware::Search::FinderCLI;
my $webapp = Slackware::Search::FinderCLI->new(
	PARAMS => {
		cfg_file => ['/home/search.slackware.eu/conf/config.pl'],
		format => 'perl',
	},
);
$webapp->run();
