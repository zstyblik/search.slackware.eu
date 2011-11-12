# 2010/Dec/08 @ Zdenek Styblik
# Desc: parse config file and return values
# Desc Alt: simple config file parser
#
# Copyright (c) 2011 Zdenek Styblik <zdenek.styblik@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
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
	open(CFGFILE, '<', $configFile) or return %configHash;
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
