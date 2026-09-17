#!/bin/bash
# audio_state.sh — settings > Audio device state (separate from volinfo).
# Emits volumes/mutes + sink/source device lists via pactl JSON.
cleanup() { jobs -p | xargs -r kill 2>/dev/null; pkill -P $$ 2>/dev/null; exit 0; }
trap cleanup EXIT TERM INT

LAST_OUTPUT=""

audio_state() {
  local sinks sources cards sink_vol source_vol sink_mute source_mute new_output

  sinks=$(pactl --format=json list sinks 2>/dev/null | jq '
    [.[] | {name: .name,
            desc: .description,
            def: (.name == $def)}]' --arg def "$(pactl get-default-sink 2>/dev/null)" 2>/dev/null)
  [[ -z "$sinks" ]] && sinks="[]"

  sources=$(pactl --format=json list sources 2>/dev/null | jq '
    [.[] | select(.monitor_source == null or (.name | endswith(".monitor") | not)) |
      {name: .name,
       desc: .description,
       def: (.name == $def)}]' --arg def "$(pactl get-default-source 2>/dev/null)" 2>/dev/null)
  [[ -z "$sources" ]] && sources="[]"

  cards=$(pactl --format=json list cards 2>/dev/null | jq '
    [.[] | {name: .name,
            desc: (.properties["device.description"] // .name),
            active: .active_profile,
            profiles: [.profiles | to_entries[]
                       | select(.value.available != "no") | .key]}]')
  [[ -z "$cards" ]] && cards="[]"

  sink_vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+(?=%)' | head -n1)
  [[ "$sink_vol" =~ ^[0-9]+$ ]] || sink_vol=0
  source_vol=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | grep -oP '\d+(?=%)' | head -n1)
  [[ "$source_vol" =~ ^[0-9]+$ ]] || source_vol=0

  sink_mute=false; source_mute=false
  pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q 'yes' && sink_mute=true
  pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q 'yes' && source_mute=true

  new_output=$(jq -nc --argjson sink_vol "$sink_vol" --argjson source_vol "$source_vol" \
    --argjson sink_mute "$sink_mute" --argjson source_mute "$source_mute" \
    --argjson sinks "$sinks" --argjson sources "$sources" \
    --argjson cards "$cards" \
    '{sink_vol: $sink_vol, source_vol: $source_vol,
      sink_mute: $sink_mute, source_mute: $source_mute,
      sinks: $sinks, sources: $sources, cards: $cards}')

  if [[ "$new_output" != "$LAST_OUTPUT" ]]; then
    echo "$new_output"
    LAST_OUTPUT="$new_output"
  fi
}

audio_state

# single event stream so concurrent runs can't pile up during slider drags
{
  pactl subscribe 2>/dev/null | grep --line-buffered -E "Event '(change|new|remove)' on (sink|source|server|card)" &
  while true; do sleep 15; echo TICK; done &
  wait
} | while read -r _; do
  while read -r -t 0.2 _; do :; done
  audio_state
done
