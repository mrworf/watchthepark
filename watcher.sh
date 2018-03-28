#!/bin/bash
#
# Simple hack which scans the AT&T Park events list and notifies a slack channel if an
# event is happening. Allowing people to plan their commute.
#

TMPFILE=/tmp/ATTPark.txt
IFS=$'\n'
WEBHOOK=

# Make sure we stand in the folder of the script
cd $(dirname $0)

if [ -f watcher.conf ]; then
	# Allows overriding the webhook, which is necessary
	source watcher.conf
fi

if [ -z ${WEBHOOK} ]; then
	echo "You haven't configured the script"
	exit 255
fi

if [ ! -f ${TMPFILE} ]; then
	if ! curl "https://events.mapchannels.com/Index.aspx?venue=539" > ${TMPFILE} 2>/dev/null ; then
		echo "Download failed"
		exit 255
	fi
fi

TIMES=$(egrep -oe 'itemtype="http://data-vocabulary.org/Event".*?>(.+?)</tr>' ${TMPFILE} | egrep -oe 'datetime="[^"]+"' | sed 's/datetime="\([^"]*\).*/\1/')

declare -a NAMES=( $(egrep -oe 'itemtype="http://data-vocabulary.org/Event".*?>(.+?)</tr>' ${TMPFILE} | egrep -oe 'itemprop="url" title="([^"]+)"' | sed 's/itemprop="url" title="\([^"]*\)"/\1/' ) )

TODAY="$(date +"%Y-%m-%d")"

I=0
GAME=false
for T in ${TIMES}; do
	if [ "${T:0:10}" = "${TODAY}" ]; then
		GAME=true
		WHAT="${NAMES[$I]}"
		WHEN="${T:11:5}"
	fi
	I=$(($I+1))
done

if ${GAME}; then
	JSON="payload={\"text\":\"<!here> Today at ${WHEN} there's an event at the AT&T Ballpark (${WHAT}). Please plan accordingly\",\"username\":\"AT&T Park\",\"icon_emoji\":\":stadium:\"}"
	curl -X POST --data-urlencode $JSON $WEBHOOK
fi

exit 0

