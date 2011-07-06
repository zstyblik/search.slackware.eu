#!/usr/bin/perl
# 2010/Dec/08 @ Zdenek Styblik
# Desc: Unified config for all Perl scripts

$CFG{DB_DSN} = 'dbi:Pg:dbname=pkgs;host=/tmp/;port=5432';
$CFG{DB_USER} = 'pkgs';
$CFG{DB_PASS} = 'swarePkgs';
$CFG{TMPL_PATH} = '/mnt/search.slackware.eu/template/';
$CFG{SQLITE_PATH} = '/mnt/search.slackware.eu/db/';
$CFG{TMPDIR} = '/mnt/tmp/search.slack/';

\%CFG;
