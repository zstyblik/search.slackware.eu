#!/usr/bin/perl
# 2010/Mar/16 @ Zdenek Styblik
# desc: compare differences in two MD5 files
# desc: for the first, check which files/pkgs got removed
# for the second, check which files/pkgs got modified
# write output into file for the later processing
#
# out file format: ?
# (a|d|m) <ColB>
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
use strict;
use warnings;

# desc: process MD5 file contents into hash array
# $file: string;
# @return: hash;
sub processFile {
	my $file = shift;
	open(FILE, $file) or die("Unable to open first file.");
	my %contents;
	while (my $line = <FILE>) {
		chomp($line);
		my @arr = split(' ', $line);
		$contents{$arr[1]} = $arr[0];
	}
	close(FILE);
	return %contents;
} # sub processFile

### MAIN ###
my $numArgs = $#ARGV + 1;

unless ($numArgs == 2) {
	print "This script requires two files as parameters.\n";
	exit 1;
}

my $fileOld = $ARGV[0];
my $fileNew = $ARGV[1];

unless ( -e $fileOld && -e $fileNew ) {
	print "One of files doesn't seem to exist.\n";
	exit 1;
}

my %contentsOld = &processFile($fileOld);
my %contentsNew = &processFile($fileNew);

my @keysDeleted;
my @keysSame;

for my $keyOld (keys(%contentsOld)) {
	unless ($contentsNew{$keyOld}) {
		push(@keysDeleted, $keyOld);
		delete($contentsOld{$keyOld});
		next;
	}
	if ($contentsOld{$keyOld} eq $contentsNew{$keyOld}) {
		push(@keysSame, $keyOld);
		delete($contentsNew{$keyOld});
		delete($contentsOld{$keyOld});
		next;
	}
}

my @keysNew;
for my $keyNew (keys(%contentsNew)) {
	unless ($contentsOld{$keyNew}) {
		push(@keysNew, $keyNew);
		delete($contentsNew{$keyNew});
	}
}

open(FILE, ">".$fileNew.".diff") or die("Unable to open diff file.");
for my $keyDeleted (@keysDeleted) {
	print FILE "D ".$keyDeleted."\n";
}
for my $keyMod (keys(%contentsNew)) {
	print FILE "M ".$keyMod."\n";
}
for my $keyNew (@keysNew) {
	print FILE "A ".$keyNew."\n";
}
close(FILE);

