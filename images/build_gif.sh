#!/usr/bin/env bash
# Build an animated GIF cycling the six key findings.
#
# The charts are not all the same height (1600x1000, 1600x720, 1600x919), and
# ffmpeg's concat demuxer requires identical dimensions. So each frame is first
# normalised onto a uniform white 900x563 canvas, then concatenated.
set -e
cd "$(dirname "$0")"

W=900; H=563
FRAMES=(01_usage_segments 02_activity_levels 03_day_breakdown
        05_hourly_activity 07_sleep_distribution 08_sleep_vs_sedentary)

rm -rf .gifwork && mkdir -p .gifwork

i=0
for f in "${FRAMES[@]}"; do
  i=$((i+1))
  ffmpeg -y -loglevel error -i "$f.png" \
    -vf "scale=${W}:${H}:force_original_aspect_ratio=decrease:flags=lanczos,\
pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=white" \
    ".gifwork/$(printf '%02d' $i).png"
done

LIST=.gifwork/list.txt
: > "$LIST"
for n in .gifwork/[0-9][0-9].png; do
  echo "file '$(basename "$n")'" >> "$LIST"
  echo "duration 2.2"           >> "$LIST"
done
# concat ignores the last entry's duration, so repeat the final frame
echo "file '$(basename "$(ls .gifwork/[0-9][0-9].png | tail -1)")'" >> "$LIST"

ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" \
  -vf "palettegen=stats_mode=diff" .gifwork/palette.png

ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -i .gifwork/palette.png \
  -lavfi "paletteuse=dither=bayer:bayer_scale=3" -loop 0 findings.gif

rm -rf .gifwork
echo "built findings.gif ($(du -k findings.gif | cut -f1) KB)"
