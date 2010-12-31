package Slackware::Search::Indexor;

use strict;
use warnings;

use base 'Slackware::Search::MainWeb';
use CGI::Application::Plugin::Routes;

sub setup {
	my $self = shift;
	$self->start_mode('home');

	$self->header_props(-type => 'text/html', -charset => 'UTF-8');
	# routes_root optionally is used to prepend a URI part to 
	# every route
	$self->routes_root('/'); 
	$self->routes([
		'' => 'home' ,
		'/about' => 'about',
		'/changelog/:slackver' => 'changelog',
		'/home' => 'home',
		'/links' => 'links',
	]);
}

sub cgiapp_init {
	my $self = shift;

	my %CFG = $self->cfg;

	$self->tmpl_path([$CFG{'TMPL_PATH'}]);

  # open database connection
	$self->dbh_config(
    $CFG{'DB_DSN'},
    $CFG{'DB_USER'},
    $CFG{'DB_PASS'},
  );
} # sub cgiapp_prerun

sub about {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "About");
	$template->param(ABOUT => 1);
	my $idSlackverStable = $self->_get_slackversion_idStable();
	$template->param(SVERSTABLE => $idSlackverStable);
	return $template->output();
}

sub changelog {
	my $self = shift;
	my $q = $self->query;
	my $slackver = $q->param('slackver');
	$slackver = lc($slackver);
	my $validSlackver = $self->_validate_slackver($slackver);
	unless ($validSlackver) {
		return $self->error("Slackware version is garbage.", 
			'/cgi-bin/search.cgi');
	}
	my $idSlackversion = $self->_get_slackver_id($slackver);
	unless ($idSlackversion) {
		return $self->error("Slackversion is not in DB.", 
			'/cgi-bin/search.cgi');
	}
	my $tmpDir = $self->conf->param('TMPDIR') || '/tmp/';
	my $changeLogPath = sprintf("%s/changelogs/%s/", 
		$tmpDir,	$slackver);
	my $changeLog = sprintf("%s/changelogs/%s/ChangeLog.htm", 
		$tmpDir,	$slackver);
	unless ( -e $changeLog) {
		my $errorMsg = sprintf("It seems ChangeLog doesn't exist for %s.",
			$slackver);
		return $self->error($errorMsg, '/cgi-bin/search.cgi');
	}
	$self->tmpl_path([$changeLogPath]);
	my $template = $self->load_tmpl($changeLog);
	return $template->output();
}

sub home {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "Slackware Unofficial Package Browser/Search");
	$template->param(HOME => 1);
	my $idSlackverStable = $self->_get_slackversion_idStable();
	$template->param(SVERSTABLE => $idSlackverStable);
	return $template->output();
}

sub links {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "Links");
	$template->param(LINKS => 1);
	my $idSlackverStable = $self->_get_slackversion_idStable();
	$template->param(SVERSTABLE => $idSlackverStable);
	return $template->output();
}

1;
