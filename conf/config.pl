#!/usr/bin/perl

$CFG{DB_DSN} =
'dbi:Pg:dbname=pkgs;host=/home/search.slackware.eu/var/run/postgres/;port=21000';
$CFG{DB_USER} = 'pkgs';
$CFG{DB_PASS} = 'swarePkgs';
$CFG{TMPL_PATH} = '/home/search.slackware.eu/template/';
$CFG{SQLITE_PATH} = '/home/search.slackware.eu/db/';

\%CFG;

