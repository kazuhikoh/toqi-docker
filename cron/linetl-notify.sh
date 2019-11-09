#!/bin/bash

PATH=$PATH:/usr/bin

readonly URL="$(config linetl.url)"
readonly DIR="/toqi/$(config linetl.dir)"
readonly PREFIX="$(config linetl.name)"
readonly SLACK_WEBHOOK="$(config linetl.slack.webhook)"
readonly SLACK_CHANNEL="$(config linetl.slack.channel)"
readonly SCRAPER="xline -cx"

readonly NOW=$(date '+%Y%m%d-%H%M%S')
readonly CURR_LOG="$DIR/$PREFIX.$NOW.log"
readonly CURR_HTML="$DIR/$PREFIX.$NOW.html"
readonly CURR_STDERR="$DIR/$PREFIX.$NOW.stderr"
readonly PREV_LOG=$(find "$DIR" -type f -name "*.log" | sort -r | head -n 1)

# to_json <channel>
to_json() {
  readonly channel="$1"

  if [ -p /dev/stdin ]; then
    local input="$(cat -)"
    [ -z "${input}" ] && exit 1

    local post="$(echo "$input" | jq -r .post)"
    local msg="$(echo "$input" | jq -r .text)"

    cat <<EOF
{
  "channel": "${channel}",
  "username": "LINE TIMELINE",
  "text": "${msg}\n\nhttps://timeline.line.me/post/${post}"
}
EOF
  fi
}

{
  [[ -d "$DIR" ]] || { mkdir -p "$DIR"; }
  
  # fetch curr
  curl -v $URL >"$CURR_HTML" 2>"$CURR_STDERR"
  
  cat "$CURR_HTML" | $SCRAPER | head -n 1 >"$CURR_LOG"
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
