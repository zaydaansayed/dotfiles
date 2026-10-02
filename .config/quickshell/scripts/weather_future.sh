#!/usr/bin/env bash

WEATHER_DATA=$(weather-Cli get -r)

CURRENT_TIME=$(date +"%Y-%m-%dT%H:00")

echo "$WEATHER_DATA" | jq -c --arg now "$CURRENT_TIME" '
(.forecast.hourly.time | index($now)) as $idx |
if $idx == null then
  {error: "Current time not found in forecast"}
else
  [range(1; 4) as $i | {
    time: (.forecast.hourly.time[$idx + $i] | split("T")[1]),
    temp: .forecast.hourly.temperature_2m[$idx + $i],
    code: .forecast.hourly.weathercode[$idx + $i]
  }]
end
'
