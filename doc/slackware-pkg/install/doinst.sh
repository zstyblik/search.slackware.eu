chown -R slacker:slacker /srv/httpd/search.slackware.eu/bin
chown slacker /srv/httpd/search.slackware.eu/db/
chown -R slacker:slacker /srv/httpd/search.slackware.eu/sbin/
chown -R slacker:slacker /srv/httpd/search.slackware.eu/shell/
chown -R slacker:slacker /mnt/tmp/search.slack/
chown -R slacker:slacker /tmp/search.slack/

chmod 640 /srv/httpd/search.slackware.eu/conf/config.pl
chown slacker:apache /srv/httpd/search.slackware.eu/conf/config.pl

chmod 640 /srv/httpd/search.slackware.eu/conf/config.sh
chown slacker:apache /srv/httpd/search.slackware.eu/conf/config.sh

mkdir /srv/httpd/search.slackware.eu/htdocs/download/
cp /srv/httpd/search.slackware.eu/shell/slacksearch.sh \
	/srv/httpd/search.slackware.eu/htdocs/download/

