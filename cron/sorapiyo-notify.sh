#!/bin/bash
set -x

PATH=$PATH:/usr/bin

readonly URL="$(config piyo.url)"
readonly DIR="/toqi/$(config piyo.dir)"
readonly PREFIX="$(config piyo.name)"
readonly SLACK_WEBHOOK="$(config piyo.slack.webhook)"
readonly SLACK_CHANNEL="$(config piyo.slack.channel)"
readonly SCRAPER="scrapiyo -l"

readonly NOW=$(date '+%Y%m%d-%H%M%S')
readonly CURR_LOG="$DIR/$PREFIX.$NOW.log"
readonly CURR_HTML="$DIR/$PREFIX.$NOW.html"
readonly CURR_STDERR="$DIR/$PREFIX.$NOW.stderr"
readonly PREV_LOG=$(ls -1 "$DIR/${PREFIX}"*".log" | sort -r | head -n 1)

# to_json <channel>
to_json() {
  readonly channel="$1"

  if [ -p /dev/stdin ]; then
    local input="$(cat -)"
    [ -z "${input}" ] && exit 1

    local url="$(echo "${input}" | grep -oP '(?<=^url=).*')"
    local time="$(echo "${input}" | grep -oP '(?<=^time=).*')"
    local messages="$(echo "${input}" | grep -oP '(?<=^message=).*')"
    local images="$(echo "${input}"   | grep -oP '(?<=^img-src=).*' | awk 'NF > 0 {printf("{\"image_url\": \"%s\"}", $0)}' | paste -s -d,)"
    cat <<EOF
{
  "channel": "${channel}",
  "username": "そらぴよ⊂(＾ω＾)⊃",
  "text": "${messages}\n<http://piyo.fc2.com${url}|${time}>",
  "attachments": [
    ${images}
  ]
}
EOF
  fi
}

{
  [[ -d "$DIR" ]] || { mkdir -p "$DIR"; }
  
  # fetch curr
  curl -v $URL >"$CURR_HTML" 2>"$CURR_STDERR"
  
  cat "$CURR_HTML" | $SCRAPER >"$CURR_LOG"
  [[ ! $? = '0' ]] && {
    mv "$CURR_LOG" "$CURR_LOG.error"
    exit 1
  }

  # diff
  [[ -z "$PREV_LOG" ]] && {
    cat "$CURR_LOG" | to_json "$SLACK_CHANNEL" | slacky -j -u "$SLACK_WEBHOOK"
    exit 0
  }

  if diff -q "$PREV_LOG" "$CURR_LOG"; then
    rm "$CURR_HTML"
    rm "$CURR_STDERR"
    rm "$CURR_LOG"
  else
    cat "$CURR_LOG" | to_json "$SLACK_CHANNEL" | slacky -j -u "$SLACK_WEBHOOK"
  fi
}
# } >/dev/null 2>/dev/null

