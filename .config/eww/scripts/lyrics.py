#!/usr/bin/env python3
import json
import time
import urllib.request
import urllib.parse
import subprocess

def get_mpris_info():
    try:
        artist = subprocess.check_output(["playerctl", "metadata", "artist"], text=True).strip()
        title = subprocess.check_output(["playerctl", "metadata", "title"], text=True).strip()
        pos = float(subprocess.check_output(["playerctl", "position"], text=True).strip())
        return artist, title, pos
    except Exception:
        return None, None, 0

def fetch_lrc(artist, title):
    try:
        url = f"https://lrclib.net/api/get?artist_name={urllib.parse.quote(artist)}&track_name={urllib.parse.quote(title)}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            if "syncedLyrics" in data and data["syncedLyrics"]:
                return parse_lrc(data["syncedLyrics"])
    except Exception:
        pass
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
    last_output = ""

    while True:
        artist, title, pos = get_mpris_info()
        track_id = f"{artist} - {title}" if (artist or title) else ""

        if track_id != current_track:
            current_track = track_id
            lyrics = fetch_lrc(artist, title) if artist and title else []
            last_output = ""

        if not lyrics:
            out = json.dumps({"past": "", "current": title if title else "No media playing", "future": ""})
            if out != last_output:
                print(out, flush=True)
                last_output = out
            time.sleep(1)
            continue

        past, current, future = "", "", ""
        for i, (t, text) in enumerate(lyrics):
            if pos >= t:
                past = lyrics[i-1][1] if i > 0 else ""
                current = text
                future = lyrics[i+1][1] if i + 1 < len(lyrics) else ""

        if not past and not current and not future and current_track:
            current = "♪♪♪"

        out = json.dumps({"past": past, "current": current, "future": future})

        if out != last_output:
            print(out, flush=True)
            last_output = out

        time.sleep(0.2)

if __name__ == "__main__":
    main()
