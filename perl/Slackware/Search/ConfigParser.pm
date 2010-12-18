# 2010/Dec/08 @ Zdenek Styblik
# Desc: parse config file and return values
# Desc Alt: simple config file parser
package Slackware::Search::ConfigParser;

require Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(_getConfig);

use strict;
use warnings;

sub _getConfig {
	my $self = shift;
	my $configFile = shift;
	my %configHash;
	return %configHash unless $configFile;
	unless ( -e $configFile ) {
		return %configHash;
	} # unless -e $configFile
	open(CFGFILE, $configFile) or return %configHash;
	while (my $line = <CFGFILE>) {
		chomp($line);
		next unless ($line =~ /^\$CFG{[A-Za-z0-9\_\-]+}.+=*;$/);
		my $left = substr($line, 0, index($line, '=')-1);
		$left =~ s/^\s+//g;
		$left =~ s/\s+$//g;
		my $key = substr($left, index($left, '{')+1, -1);

		my $right = substr($line, index($line, '=')+1, rindex($line, ';'));
		$right = substr($right, 0, rindex($right, ';'));
		$right =~ s/^\s+//g;
		$right =~ s/\s+$//g;
		my $value;
		if ($right =~ /^'.*'$/ || $right =~ /^".*"$/) {
			$value = substr($right, 1, length($right));
			chop($value);
		} else {
			$value = $right;
		}
		$configHash{$key} = $value;
	} # while my $line
	close(CFGFILE);
	return %configHash;
} # sub getConfig

1;
