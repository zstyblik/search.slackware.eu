grep -q -e 'slacker' || useradd -s /bin/bash \
	-d /mnt/search.slackware.eu/home/ -U -m slacker

chown -R slacker:slacker /srv/httpd/search.slackware.eu/bin
chown slacker /srv/httpd/search.slackware.eu/db/
chown -R slacker:slacker /srv/httpd/search.slackware.eu/sbin/
chown -R slacker:slacker /srv/httpd/search.slackware.eu/shell/
if [ ! -d /mnt/tmp/search.slack ]; then
	mkdir /mnt/tmp/search.slack
fi
chown -R slacker:slacker /mnt/tmp/search.slack/;

if [ ! -d /tmp/search.slack ]; then
	mkdir /tmp/search.slack/;
fi
chown -R slacker:slacker /tmp/search.slack/

chmod 640 /srv/httpd/search.slackware.eu/conf/config.pl
chown slacker:apache /srv/httpd/search.slackware.eu/conf/config.pl

chmod 640 /srv/httpd/search.slackware.eu/conf/config.sh
chown slacker:apache /srv/httpd/search.slackware.eu/conf/config.sh

mkdir /srv/httpd/search.slackware.eu/htdocs/download/
cp /srv/httpd/search.slackware.eu/shell/slacksearch.sh \
	/srv/httpd/search.slackware.eu/htdocs/download/

