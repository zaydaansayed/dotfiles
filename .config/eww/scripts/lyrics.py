#!/usr/bin/env python3
import json
import time
import urllib.request
import urllib.parse
import subprocess
import bisect

LRC_CACHE = {}

def get_mpris_info():
    try:
        output = subprocess.check_output(
            ["playerctl", "metadata", "--format", "{{artist}}\t{{title}}\t{{position}}"],
            text=True
        ).strip()
        parts = output.split('\t')
        if len(parts) >= 3:
            artist = parts[0].strip()
            title = parts[1].strip()
            pos = float(parts[2].strip()) / 1000000.0 if parts[2].strip().isdigit() else 0.0
            return artist, title, pos
    except Exception:
        pass
    return None, None, 0.0

def fetch_lrc(artist, title):
    track_key = f"{artist} - {title}"
    if track_key in LRC_CACHE:
        return LRC_CACHE[track_key]

    try:
        url = f"https://lrclib.net/api/get?artist_name={urllib.parse.quote(artist)}&track_name={urllib.parse.quote(title)}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=3) as response:
            data = json.loads(response.read().decode())
            if "syncedLyrics" in data and data["syncedLyrics"]:
                parsed = parse_lrc(data["syncedLyrics"])
                LRC_CACHE[track_key] = parsed
                return parsed
    except Exception:
        pass

    LRC_CACHE[track_key] = []
    return []

def parse_lrc(lrc_text):
    lines = []
    for line in lrc_text.splitlines():
        if line.startswith('[') and ']' in line:
            parts = line.split(']', 1)
            time_str = parts[0][1:]
            text = parts[1].strip()
            try:
                m, s = time_str.split(':')
                timestamp = float(m) * 60 + float(s)
                lines.append((timestamp, text))
            except ValueError:
                continue
    return sorted(lines, key=lambda x: x[0])

def main():
    current_track = ""
    lyrics = []
    timestamps = []
    last_output = ""

    while True:
        artist, title, pos = get_mpris_info()
        track_id = f"{artist} - {title}" if (artist or title) else ""

        if track_id != current_track:
            current_track = track_id
            lyrics = fetch_lrc(artist, title) if artist and title else []
            timestamps = [t[0] for t in lyrics]
            last_output = ""

        if not lyrics:
            out = json.dumps({"past": "", "current": title if title else "No media playing", "future": ""})
            if out != last_output:
                print(out, flush=True)
                last_output = out
            time.sleep(1)
            continue

        idx = bisect.bisect_right(timestamps, pos) - 1

        past = lyrics[idx - 1][1] if idx > 0 else ""
        current = lyrics[idx][1] if idx >= 0 else "♪♪♪"
        future = lyrics[idx + 1][1] if (0 <= idx < len(lyrics) - 1) else ""

        out = json.dumps({"past": past, "current": current, "future": future})

        if out != last_output:
            print(out, flush=True)
            last_output = out

        time.sleep(0.2)

if __name__ == "__main__":
    main()
