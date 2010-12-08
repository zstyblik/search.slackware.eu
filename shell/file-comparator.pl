#!/usr/bin/perl
# 2010/Mar/16 @ Zdenek Styblik
# desc: compare differences in two MD5 files
# desc: for the first, check which files/pkgs got removed
# for the second, check which files/pkgs got modified
# write output into file for the later processing
#
# out file format: ?
# (a|d|m) <ColB>

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

