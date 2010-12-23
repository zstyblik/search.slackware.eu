package Slackware::Search::MainWeb;

use strict;
use warnings;

use base 'CGI::Application';
use CGI::Application::Plugin::ConfigAuto (qw/cfg/);
use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::Redirect;

sub error {
	my $self = shift;
	my $error = shift;
	my $redir = shift || $ENV{'SCRIPT_NAME'};
	my $template = $self->load_tmpl('index.htm');
	$template->param(ERROR => $error);
	$template->param(REDIRECT => $redir);
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
# desc: return haystacks
# $idHaystack: integer;
# @return: array;
sub _get_haystacks {
	my $self = shift;
	my $idHaystack = shift || -1;
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
# desc: return slackversions in db
# $idSlackver: integer;
# @return: array;
sub _get_slackversions {
	my $self = shift;
	my $idSlackver = shift || -1;
	unless ($idSlackver =~ /^[0-9]$/) {
		$idSlackver = -1;
	}
	my $dbh = $self->dbh;

	if ($idSlackver == -1) {
		my $sql1 = "SELECT id_slackversion FROM slackversion WHERE \
		version <> 9999 ORDER BY version DESC LIMIT 1;";
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

1;
