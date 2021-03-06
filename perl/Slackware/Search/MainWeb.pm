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
package Slackware::Search::MainWeb;

use constant CONFIG_FILE => '/mnt/search.slackware.eu/conf/config.pl';

use strict;
use warnings;

use base 'CGI::Application';
use Carp;
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::Redirect;
use Slackware::Search::ConfigParser (qw/_getConfig/);

sub cgiapp_prerun {
	my $self = shift;

	my %CFG = $self->_get_config;

	$self->param('CONFIG', \%CFG);

	$self->tmpl_path([$CFG{'TMPL_PATH'}]);

	$self->dbh_config(
		$CFG{'DB_DSN'},
		$CFG{'DB_USER'},
		$CFG{'DB_PASS'},
	);
} # sub cgiapp_prerun
sub error {
	my $self = shift;
	my $error = shift;
	my $redir = shift || $ENV{'SCRIPT_NAME'};
	my $template = $self->load_tmpl('index.htm');
	$template->param(ERROR => $error);
	$template->param(REDIRECT => $redir);
	$template->param(TITLE => 'ErRor');
	return $template->output();
} # sub error

sub teardown {
	my $self = shift;
	my $dbh = $self->dbh;
	$dbh->disconnect() if ($dbh);
} # sub teardown
# desc: return categories of slackversion;
# $idSlackVer: integer;
# @return: array;
sub _get_categories  {
	my $self = shift;
# future
#	my $idSlackVer = shift;
	my $dbh = $self->dbh;
	my $sql1 = "SELECT id_category, category_name FROM category;";
	my $result1 = $dbh->selectall_arrayref($sql1, { Slice => {} });
	my @cats;
	for my $row (@$result1) {
		my %item = (IDCAT => $row->{id_category}, 
			CATNAME => $row->{category_name}, 
		);
		push(@cats, \%item);
	}
	return @cats;
} # sub _get_categories
# desc: return config as hash arr
# @return: hashArr
sub _get_config {
	my $configFile = CONFIG_FILE || undef;
	my $configPBash = 'Slackware::Search::ConfigParser';
	my %configParsed = $configPBash->_getConfig($configFile);
	if (!%configParsed) {
		carp "Unable to parse config file.";
	}
	return %configParsed;
} # sub _get_config
# desc: return haystacks
# $idHaystack: integer;
# @return: array;
sub _get_haystacks {
	my $self = shift;
	my $idHaystack = shift || 'garbage';
	my @haystacks;
	unless ($idHaystack =~ /^[0-9]+$/) {
		return @haystacks;
	}
	my %files = (IDHAYSTACK => 1,
		HAYDESC => 'files',
		SELECTED => '',
	);
	my %pkgs = (IDHAYSTACK => 2,
		HAYDESC => 'packages',
		SELECTED => '',
	);
	if ($idHaystack == 1) {
		$files{SELECTED} = ' selected="selected"';
	} else {
		$pkgs{SELECTED} = ' selected="selected"';
	}
	push(@haystacks, \%files);
	push(@haystacks, \%pkgs);
	return @haystacks;
} # sub _get_haystacks
# desc: return id_category
# $category: string;
# @return: int;
sub _get_category_id {
	my $self = shift;
	my $category = shift || '';
	if ($category !~ /^[A-Za-z0-9]+$/) {
		return 0;
	}
	my $dbh = $self->dbh;
	my $sql1 = sprintf("SELECT id_category FROM category WHERE 
		category_name = '%s';", $category);
	my $result1 = $dbh->selectrow_array($sql1);
	return 0 unless $result1;
	return $result1;
} # sub _get_category_id
# desc: look up serie ID
# $serie: string;
# @return: int;
sub _get_serie_id {
	my $self = shift;
	my $serie = shift || '';
	if ($serie !~ /^[A-Za-z0-9\-\_\.\/]+$/) {
		return 0;
	}
	my $dbh = $self->dbh;
	my $sql1 = sprintf("SELECT id_serie FROM serie WHERE 
		serie_name = '%s';", $serie);
	my $result1 = $dbh->selectrow_array($sql1);
	return 0 unless $result1;
	return $result1;
} # sub _get_serie_id
# desc: look up slackware version ID
# $slackver: string;
# @return: int;
sub _get_slackversion_id {
	my $self = shift;
	my $slackver = shift || '';
	if ($slackver !~ /^[A-Za-z0-9\-\.]+$/) {
		return 0;
	}
	my $dbh = $self->dbh;
	my $sql1 = sprintf("SELECT id_slackversion FROM slackversion WHERE 
		slackversion_name = '%s';", $slackver);
	my $result1 = $dbh->selectrow_array($sql1);
	return 0 unless $result1;
	return $result1;
} # sub _get_slackversion_id
# desc: return slackversion name (string)
# $idSlackversion: int;
# @return: string/undef;
sub _get_slackversion_name {
	my $self = shift;
	my $idSlackversion = shift;
	unless ($idSlackversion =~ /^[0-9]+$/) {
		return undef;
	}
	my $dbh = $self->dbh;

	my $sql1 = "SELECT COUNT(*) FROM slackversion WHERE \
	id_slackversion = $idSlackversion;";
	if ($dbh->selectrow_array($sql1) == 0) {
		return undef;
	}

	my $sql2 = "SELECT slackversion_name FROM slackversion WHERE \
	id_slackversion = $idSlackversion LIMIT 1;";
	my $slackversion = $dbh->selectrow_array($sql2);
	return $slackversion;
} # sub _get_slackversion_name
# desc: return ID of stable slackversion
# @return: int;
sub _get_slackversion_idStable {
	my $self = shift;
	my $dbh = $self->dbh;
	my $sql1 = "SELECT id_slackversion FROM slackversion WHERE \
	version <> 9999 AND slackversion_name NOT LIKE 'slackware64-%' \
	ORDER BY version DESC LIMIT 1;";
	my $idSlackver = $dbh->selectrow_array($sql1);
	unless ($idSlackver) {
		my $sql2 = "SELECT id_slackversion FROM slackversion WHERE \
		version <> 9999 ORDER BY version DESC LIMIT 1;";
		$idSlackver = $dbh->selectrow_array($sql2);
	}
	return 0 unless ($idSlackver);
	return $idSlackver;
} # sub _get_slackversion_idStable 
# desc: return slackversions in db
# $idSlackver: integer;
# @return: array;
sub _get_slackversions {
	my $self = shift;
	my $idSlackver = shift || 'garbage';
	unless ($idSlackver =~ /^[0-9]+$/) {
		$idSlackver = 0;
	}
	my $dbh = $self->dbh;

	if ($idSlackver == 0) {
		my $sql1 = "SELECT id_slackversion FROM slackversion WHERE \
		version <> 9999 AND slackversion_name NOT LIKE 'slackware64-%' \
		ORDER BY version DESC LIMIT 1;";
		$idSlackver = $dbh->selectrow_array($sql1);
	}

	my $sql2 = "SELECT id_slackversion, slackversion_name FROM \
	slackversion ORDER BY version DESC, slackversion_name DESC;";
	my $result2 = $dbh->selectall_arrayref($sql2, { Slice => {} });
	my @slackVers;
	for my $row (@$result2) {
		my $selected = '';
		if ($idSlackver == $row->{id_slackversion}) {
			$selected = ' selected="selected"';
		}
		my %item = ( IDSVER => $row->{id_slackversion}, 
			SVERNAME => $row->{slackversion_name},
			SELECTED => $selected,
		);
		push(@slackVers, \%item);
	}
	return @slackVers;
} # sub _get_slackversions
# desc: return nfo about slackware versions in db
# @return: array;
sub _get_slackversions_nfo {
	my $self = shift;
	my @slackvernfo;

	my $dbh = $self->dbh;
	my $sql1 = "SELECT slackversion_name, \
	to_char(ts_last_update, 'YYYY/MM/DD HH24:MI:SS') AS \
	ts_last_update, no_files, no_pkgs FROM slackversion ORDER BY \
	version DESC, slackversion_name DESC;";
	my $result1 = $dbh->selectall_arrayref($sql1, { Slice => {}});

	unless ($result1) {
		return @slackvernfo;
	}

	for my $row1 (@$result1) {
		my %item = (SVER => $row1->{slackversion_name},
			NOPKGS => $row1->{no_pkgs},
			NOFILES => $row1->{no_files},
			LUPDATE => $row1->{ts_last_update},
		);
		push(@slackvernfo, \%item);
	}

	return @slackvernfo;
} # sub _get_slackversions_nfo
# desc: validate input ~ category
# $category: string;
# @return: bool;
sub _validate_category {
	my $self = shift;
	my $category = shift || '';
	return 0 unless ($category);
	return 0 if ($category !~ /^[A-Za-z0-9]+$/);
	return 1;
} # sub _validate_category
# desc: validate input ~ package
# $package: string;
# @return: bool;
sub _validate_package {
	my $self = shift;
	my $package = shift || '';
	return 0 unless ($package);
	return 0 if ($package !~ /^[A-Za-z0-9@\+\-\.\_]+\.t(g|x)z$/);
	return 1;
} # sub _validate_package
# desc; validate input ~ serie
# $serie: string;
# @return: bool;
sub _validate_serie {
	my $self = shift;
	my $serie = shift || '';
	return 0 unless ($serie);
	return 0 if ($serie !~ /^[A-Za-z0-9\-\_\.\/]+$/);
	return 1;
} # sub _validate_serie
# desc: validate input
# $slackver: string;
# @return: bool;
sub _validate_slackver {
	my $self = shift;
	my $slackver = shift || '';
	return 0 unless ($slackver);
	return 0 if ($slackver !~ /^[A-Za-z0-9\-\.]+$/);
	return 1;
} # sub _validate_slackver
# desc: encode URL
# $URL: string;
# @return: string;
sub _url_encode {
	my $self = shift;
	my $URL = shift || '';
	return 0 unless ($URL);
	$URL =~ s/([^A-Za-z0-9@\-\_\.])/sprintf("%%%02X", ord($1))/seg;
	return $URL;
} # sub _encode_URL
# desc: decode URL
# $URL: string;
# @return: string;
sub _url_decode {
	my $self = shift;
	my $URL = shift || '';
	return 0 unless ($URL);
	$URL =~ s/\%([A-Fa-f0-9@\-\_\.]{2})/pack('C', hex($1))/seg;
	return $URL;
} # sub _decode_URL

1;
