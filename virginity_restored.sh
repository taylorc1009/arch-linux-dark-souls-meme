#!/usr/bin/env bash
# Arch logo + Dark Souls style fade-in banner.
# Needs a 256-color terminal. Press Ctrl+C to quit early.

TEXT="V I R G I N I T Y   R E S T O R E D"
SEARCH_FOR_SOUND="bonfire.ogg"

# Dark -> gold ramp (xterm 256-color codes)
RAMP=(233 235 237 239 58 94 100 136 172 178 214 220 221 222)

# Sound effect: pass a file as the first argument, or put one at the default path.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOUND="$SCRIPT_DIR/$SEARCH_FOR_SOUND"
SND_PID=""

# Runs in a background subshell; exec makes the player's PID the one we track.
play_sound() {
    [[ -f $SOUND ]] || return
    if   command -v mpv     >/dev/null; then exec mpv --no-video --really-quiet "$SOUND"
    elif command -v ffplay  >/dev/null; then exec ffplay -nodisp -autoexit -loglevel quiet "$SOUND"
    elif command -v pw-play >/dev/null; then exec pw-play "$SOUND"
    elif command -v paplay  >/dev/null; then exec paplay "$SOUND"
    elif command -v play    >/dev/null; then exec play -q "$SOUND"
    elif command -v aplay   >/dev/null; then exec aplay -q "$SOUND"
    fi
}

mapfile -t LOGO <<'EOF'
                   -`
                  .o+`
                 `ooo/
                `+oooo:
               `+oooooo:
               -+oooooo+:
             `/:-:++oooo+:
            `/++++/+++++++:
           `/++++++++++++++:
          `/+++ooooooooooooo/`
         ./ooosssso++osssssso+`
        .oossssso-````/ossssss+`
       -osssssso.      :ssssssso.
      :osssssss/        osssso+++.
     /ossssssss/        +ssssooo/-
   `/ossssso+/:-        -:/+osssso+-
  `+sso+:-`                 `.-/+oso:
 `++:.                           `-/+/
 .`                                 `/
EOF

cleanup() {
    [[ -n $SND_PID ]] && kill "$SND_PID" 2>/dev/null
    printf '\e[0m\e[?25h\e[?1049l'   # reset colors, show cursor, leave alt screen
}
trap cleanup EXIT
trap 'exit 0' INT TERM

cols=$(tput cols)
rows=$(tput lines)

# Logo dimensions
logo_h=${#LOGO[@]}
logo_w=0
for line in "${LOGO[@]}"; do
    (( ${#line} > logo_w )) && logo_w=${#line}
done

top=$(( (rows - logo_h) / 2 + 1 ))
left=$(( (cols - logo_w) / 2 + 1 ))
(( top < 1 )) && top=1
(( left < 1 )) && left=1

printf '\e[?1049h\e[?25l\e[2J'   # alt screen, hide cursor, clear

# Draw logo in Arch blue
printf '\e[1;38;5;39m'
for i in "${!LOGO[@]}"; do
    printf '\e[%d;%dH%s' $(( top + i )) "$left" "${LOGO[i]}"
done
printf '\e[0m'
sleep 1.5

# Dark band across the middle of the screen
mid=$(( rows / 2 + 1 ))
band() {  # row, bg color
    printf '\e[%d;1H\e[48;5;%dm%*s\e[0m' "$1" "$2" "$cols" ""
}
band $(( mid - 2 )) 233
band $(( mid - 1 )) 16
band "$mid"         16
band $(( mid + 1 )) 16
band $(( mid + 2 )) 233

# Fade the text in
text_col=$(( (cols - ${#TEXT}) / 2 + 1 ))
(( text_col < 1 )) && text_col=1
play_sound >/dev/null 2>&1 </dev/null &
SND_PID=$!
for c in "${RAMP[@]}"; do
    band "$mid" 16
    printf '\e[%d;%dH\e[48;5;16m\e[1;38;5;%dm%s\e[0m' "$mid" "$text_col" "$c" "$TEXT"
    sleep 0.2
done

sleep 4
