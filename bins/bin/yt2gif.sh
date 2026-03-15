#!/usr/bin/env bash
set -euo pipefail

# yt2gif.sh
# Dependencies: yt-dlp, ffmpeg
# Optional: gifski (higher-quality GIF encoder)

usage() {
  cat <<'EOF'
Usage:
  yt2gif.sh URL START END [OUT.gif]

Arguments:
  URL        YouTube video URL
  START      mm:ss or hh:mm:ss[.ms]
  END        mm:ss or hh:mm:ss[.ms]  (must be > START)
  OUT.gif    optional output path (default: ./out.gif)

Environment knobs (optional):
  MAX_MB=15          Target max size in MB (default: 15)
  FPS=15             Initial GIF fps (default: 15)
  WIDTH=640          Initial scale width (default: 640; height auto)
  MIN_FPS=10         Lower bound when compressing (default: 10)
  MIN_WIDTH=360      Lower bound when compressing (default: 360)
  USE_GIFSKI=0|1     Use gifski if installed (default: 0)
  GIFSKI_QUALITY=80  gifski quality (default: 80, 1..100)

Examples:
  ./yt2gif.sh "https://youtu.be/VIDEO" 01:12 01:19 clip.gif
  MAX_MB=8 FPS=12 WIDTH=540 ./yt2gif.sh "URL" 00:30 00:38
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

# Parse time string to seconds (supports mm:ss, hh:mm:ss, with optional .ms)
to_seconds() {
  local t="$1"
  local frac="0"
  if [[ "$t" == *.* ]]; then
    frac="${t#*.}"
    t="${t%.*}"
  fi

  IFS=: read -r a b c <<<"$t"
  local h=0 m=0 s=0

  if [[ -z "${b:-}" ]]; then
    # "SS" not allowed by user; keep strict
    die "Time must be mm:ss or hh:mm:ss (got: $1)"
  fi

  if [[ -z "${c:-}" ]]; then
    # mm:ss
    m="$a"; s="$b"
  else
    # hh:mm:ss
    h="$a"; m="$b"; s="$c"
  fi

  [[ "$h" =~ ^[0-9]+$ ]] || die "Invalid hours in time: $1"
  [[ "$m" =~ ^[0-9]+$ ]] || die "Invalid minutes in time: $1"
  [[ "$s" =~ ^[0-9]+$ ]] || die "Invalid seconds in time: $1"
  [[ "$frac" =~ ^[0-9]+$ ]] || die "Invalid milliseconds in time: $1"

  # normalize ms to fractional seconds (keep 3 digits max)
  if (( ${#frac} > 3 )); then frac="${frac:0:3}"; fi
  while (( ${#frac} < 3 )); do frac="${frac}0"; done

  # Return as a decimal string (ffmpeg-friendly)
  local base=$((10#$h*3600 + 10#$m*60 + 10#$s))
  if [[ "$frac" == "000" ]]; then
    echo "$base"
  else
    printf "%d.%03d" "$base" "$((10#$frac))"
  fi
}

have() { command -v "$1" >/dev/null 2>&1; }

main() {
  [[ $# -ge 3 ]] || { usage; exit 1; }
  [[ "$1" != "-h" && "$1" != "--help" ]] || { usage; exit 0; }

  local url="$1"
  local start_raw="$2"
  local end_raw="$3"
  local out="${4:-out.gif}"

  have yt-dlp || die "yt-dlp not found"
  have ffmpeg || die "ffmpeg not found"

  local max_mb="${MAX_MB:-15}"
  local fps0="${FPS:-15}"
  local width0="${WIDTH:-640}"
  local min_fps="${MIN_FPS:-10}"
  local min_width="${MIN_WIDTH:-360}"
  local use_gifski="${USE_GIFSKI:-0}"
  local gifski_q="${GIFSKI_QUALITY:-80}"

  local start_s end_s
  start_s="$(to_seconds "$start_raw")"
  end_s="$(to_seconds "$end_raw")"

  # Compare as float using awk
  awk -v a="$start_s" -v b="$end_s" 'BEGIN{exit !(b>a)}' || die "END must be greater than START"

  # Format for yt-dlp section download: *START-END (seconds OK)
  local section="*${start_s}-${end_s}"

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  local mp4="$tmp/clip.mp4"

  # Download only the requested section (requires ffmpeg installed)
  # Try to keep it mp4-compatible for simplest downstream.
  yt-dlp \
    --no-playlist \
    --download-sections "$section" \
    --force-keyframes-at-cuts \
    -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/best" \
    --merge-output-format mp4 \
    -o "$tmp/dl.%(ext)s" \
    "$url" >/dev/null

  # yt-dlp may output a different name; find the merged mp4
  local found
  found="$(ls -1 "$tmp"/*.mp4 2>/dev/null | head -n 1 || true)"
  [[ -n "$found" ]] || die "Failed to download section as mp4"
  mv "$found" "$mp4"

  # Encode attempt loop: lower width then fps until size <= max_mb or floors reached.
  local fps="$fps0"
  local width="$width0"
  local attempt=1
  local max_bytes=$(( max_mb * 1024 * 1024 ))

  while :; do
    local gif="$tmp/out_${attempt}.gif"
    local palette="$tmp/palette_${attempt}.png"

    # Filters:
    # - fps for size control
    # - scale to WIDTH keeping aspect ratio
    # - palettegen/paletteuse for quality
    local vf_base="fps=${fps},scale=${width}:-1:flags=lanczos"
    ffmpeg -hide_banner -loglevel error -y \
      -i "$mp4" \
      -vf "${vf_base},palettegen=stats_mode=diff" \
      "$palette"

    if [[ "$use_gifski" == "1" && $(have gifski; echo $?) -eq 0 ]]; then
      # frames -> gifski
      local frames_dir="$tmp/frames_${attempt}"
      mkdir -p "$frames_dir"
      ffmpeg -hide_banner -loglevel error -y \
        -i "$mp4" \
        -vf "${vf_base}" \
        -vsync 0 \
        "$frames_dir/frame_%06d.png"

      # gifski uses its own palette; still generally good quality at smaller sizes.
      gifski --quality "$gifski_q" --fps "$fps" -o "$gif" "$frames_dir"/frame_*.png
    else
      ffmpeg -hide_banner -loglevel error -y \
        -i "$mp4" -i "$palette" \
        -lavfi "${vf_base}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
        -loop 0 \
        "$gif"
    fi

    local size
    size="$(stat -c %s "$gif")"

    if (( size <= max_bytes )); then
      mv "$gif" "$out"
      echo "OK: wrote $out ($(awk -v s="$size" 'BEGIN{printf "%.2f", s/1024/1024}') MB)  fps=$fps width=$width"
      break
    fi

    # If too big, degrade (width first, then fps)
    if (( width > min_width )); then
      width=$(( width - 80 ))
      if (( width < min_width )); then width="$min_width"; fi
    elif (( fps > min_fps )); then
      fps=$(( fps - 1 ))
      if (( fps < min_fps )); then fps="$min_fps"; fi
    else
      # Give best effort output (largest attempt) even if > MAX_MB
      mv "$gif" "$out"
      echo "Unverified: could not reach <= ${max_mb}MB without going below floors; wrote best-effort $out ($(awk -v s="$size" 'BEGIN{printf "%.2f", s/1024/1024}') MB)  fps=$fps width=$width"
      break
    fi

    attempt=$((attempt + 1))
    (( attempt <= 20 )) || die "Too many attempts; adjust MAX_MB/FPS/WIDTH"
  done
}

main "$@"
