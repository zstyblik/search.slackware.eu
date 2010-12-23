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

} # sub cgiapp_prerun

# desc: teardown overload due to absence of DBH!
sub teardown {
	my $self = shift;
} # sub teardown

sub about {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "About");
	$template->param(ABOUT => 1);
	return $template->output();
}

sub changelog {
	my $self = shift;
	my $q = $self->query;
	my $slackver = $q->param('slackversion');
	$slackver = lc($slackver);
	unless ($slackver =~ /.../) {
		return $self->error("Slackware version is garbage.");
	}
#	my $changeLogPath = sprintf("%s/%s/ChangeLog.txt", $CFG{CHANGELOGPATH},
#		$slackver);
#	unless ( -e $changeLogPath) {
#		my $errorMsg = sprintf("It seems ChangeLog doesn't exist for %s.",
#			$slackver);
#		return $self->error($errorMsg);
#	}
	my $template = $self->load_tmpl("index.htm");
	my $pageTitle = sprintf("ChangeLog %s", $slackver);
	$template->param(TITLE => $pageTitle);
	$template->param(CHANGELOG => 1);
	return $template->output();
}

sub home {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "Slackware UnOfficial Package Browser/Search");
	$template->param(HOME => 1);
	return $template->output();
}

sub links {
	my $self = shift;
	my $template = $self->load_tmpl("index.htm");
	$template->param(TITLE => "Links");
	$template->param(LINKS => 1);
	return $template->output();
}

1;
