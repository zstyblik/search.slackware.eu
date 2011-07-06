config() {
  NEW=${1:-''}
  if [ -z "${NEW}" ]; then
    return 1
  fi
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  # If there's no config file by that name, mv it over:
  NEWMD5="$(cat $NEW | md5sum)"
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "$(cat $OLD | md5sum)" = "${NEWMD5}" ]; then
    # toss the redundant copy
    rm $NEW
  fi
  # Otherwise, we leave the .new copy for the admin to consider...
	return 0
}

# If user 'slacker' doesn't exist, add him
if ! grep -q -e 'slacker' /etc/passwd ; then
	useradd -s /bin/bash -d /mnt/search.slackware.eu/home/ -U -m slacker
fi

chown -R slacker:slacker /mnt/search.slackware.eu/bin
chown slacker /mnt/search.slackware.eu/db/
chown -R slacker:slacker /mnt/search.slackware.eu/sbin/
chown -R slacker:slacker /mnt/search.slackware.eu/shell/
if [ ! -d /mnt/tmp/search.slack ]; then
	mkdir /mnt/tmp/search.slack
fi
chown -R slacker:slacker /mnt/tmp/search.slack/;

if [ ! -d /tmp/search.slack ]; then
	mkdir /tmp/search.slack/;
fi
chown -R slacker:slacker /tmp/search.slack/

cd /mnt/search.slackware.eu
config conf/config.sh.new
config conf/config.pl.new
config conf/crontab.new

if [ ! -d /mnt/search.slackware.eu/htdocs/download/ ]; then
	mkdir /mnt/search.slackware.eu/htdocs/download/
fi
cp /mnt/search.slackware.eu/shell/slacksearch.sh \
	/mnt/search.slackware.eu/htdocs/download/

cd /mnt/search.slackware.eu
chown -R lighttpd:lighttpd cgi-bin htdocs perl template
chmod -R o-rwx cgi-bin htdocs perl template
chmod o+rx perl perl/Slackware/ perl/Slackware/Search template
chmod o+r perl/Slackware/Search/* template/*
#
chmod 750 conf
#
chown slacker:lighttpd conf
chmod 640 /mnt/search.slackware.eu/conf/config.sh
chown slacker:lighttpd /mnt/search.slackware.eu/conf/config.sh
#
chmod 640 /mnt/search.slackware.eu/conf/config.pl
chown slacker:lighttpd /mnt/search.slackware.eu/conf/config.pl

