#!/bin/bash
# Tsugaru Input Setup V9
# Auto calibration:
# SELECT -> UP -> DOWN -> LEFT -> RIGHT -> A -> B -> START -> L1 -> R1 -> L2 -> R2
#
# D-PAD:
#   EV_ABS -> auto detect X/Y axis and reverse direction
#   EV_KEY -> auto detect four direction key codes

BASE="/userdata/system/tsugaru"
OUTPUT="$BASE/input.cfg"
NEWCFG="$BASE/input.cfg.new"
BACKUP="$BASE/input.cfg.bak"
LOG="$BASE/input_test_v9.log"
FB="/dev/fb0"
EVTEST="/usr/bin/evtest"
TMP="/tmp/tsugaru_input_v9.$$"

mkdir -p "$BASE"
: >"$LOG"
rm -f "$NEWCFG" "$TMP" "$TMP.capture"

cleanup()
{
    rm -f "$TMP" "$TMP.capture" "$NEWCFG"
}

trap cleanup EXIT INT TERM

log()
{
    printf '%s\n' "$*" >>"$LOG"
}

log "===== TSUGARU INPUT SETUP V9 ====="
log "DATE: $(date 2>/dev/null)"
log "OUTPUT: $OUTPUT"

[ -e "$FB" ] || {
    log "ERROR: /dev/fb0 not found"
    exit 1
}

[ -x "$EVTEST" ] || {
    log "ERROR: evtest not found"
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    log "ERROR: python3 not found"
    exit 1
}


# ------------------------------------------------------------
# Framebuffer message
# ------------------------------------------------------------

show_screen()
{
python3 - "$FB" "$1" "$2" "$3" >>"$LOG" 2>&1 <<'PY'
import os
import sys
import fcntl
import struct

fb,title,l1,l2=sys.argv[1:5]

V=0x4600
F=0x4602

font={
'A':["01110","10001","10001","11111","10001","10001","10001"],
'B':["11110","10001","10001","11110","10001","10001","11110"],
'C':["01111","10000","10000","10000","10000","10000","01111"],
'D':["11110","10001","10001","10001","10001","10001","11110"],
'E':["11111","10000","10000","11110","10000","10000","11111"],
'F':["11111","10000","10000","11110","10000","10000","10000"],
'G':["01110","10001","10000","10111","10001","10001","01110"],
'H':["10001","10001","10001","11111","10001","10001","10001"],
'I':["11111","00100","00100","00100","00100","00100","11111"],
'K':["10001","10010","10100","11000","10100","10010","10001"],
'L':["10000","10000","10000","10000","10000","10000","11111"],
'M':["10001","11011","10101","10101","10001","10001","10001"],
'N':["10001","11001","10101","10011","10001","10001","10001"],
'O':["01110","10001","10001","10001","10001","10001","01110"],
'P':["11110","10001","10001","11110","10000","10000","10000"],
'R':["11110","10001","10001","11110","10100","10010","10001"],
'S':["01111","10000","10000","01110","00001","00001","11110"],
'T':["11111","00100","00100","00100","00100","00100","00100"],
'U':["10001","10001","10001","10001","10001","10001","01110"],
'V':["10001","10001","10001","10001","10001","01010","00100"],
'W':["10001","10001","10001","10101","10101","11011","10001"],
'X':["10001","10001","01010","00100","01010","10001","10001"],
'Y':["10001","10001","01010","00100","00100","00100","00100"],
'0':["01110","10001","10011","10101","11001","10001","01110"],
'1':["00100","01100","00100","00100","00100","00100","01110"],
'2':["01110","10001","00001","00010","00100","01000","11111"],
'3':["11110","00001","00001","01110","00001","00001","11110"],
'4':["00010","00110","01010","10010","11111","00010","00010"],
'5':["11111","10000","10000","11110","00001","00001","11110"],
'6':["01110","10000","10000","11110","10001","10001","01110"],
'7':["11111","00001","00010","00100","01000","01000","01000"],
'8':["01110","10001","10001","01110","10001","10001","01110"],
'9':["01110","10001","10001","01111","00001","00001","01110"],
' ':["00000"]*7,
'-':["00000","00000","00000","11111","00000","00000","00000"]
}

fd=os.open(fb,os.O_RDWR)

try:
    v=bytearray(160)
    fcntl.ioctl(fd,V,v,True)

    x,y,xv,yv,xo,yo,bpp=struct.unpack_from("IIIIIII",v,0)

    f=bytearray(80)
    fcntl.ioctl(fd,F,f,True)

    stride=struct.unpack_from("I",f,48)[0]

    red=struct.unpack_from("III",v,32)
    green=struct.unpack_from("III",v,44)
    blue=struct.unpack_from("III",v,56)
    alpha=struct.unpack_from("III",v,68)

    if bpp!=32 or stride<x*4:
        raise RuntimeError("unsupported framebuffer")

    def pix(r,g,b,a=255):
        q=(r<<red[0])|(g<<green[0])|(b<<blue[0])
        if alpha[1]:
            q|=a<<alpha[0]
        return struct.pack("<I",q)

    white=pix(255,255,255)
    frame=bytearray(stride*y)

    lines=[title.upper(),"",l1.upper(),l2.upper()]
    longest=max(1,max(map(len,lines)))

    scale=max(1,min((x-32)//(longest*6),y//55,8))

    cw=6*scale
    ch=10*scale
    y0=max(0,(y-len(lines)*ch)//2)

    for li,text in enumerate(lines):
        x0=max(0,(x-len(text)*cw)//2)

        for ci,c in enumerate(text):
            glyph=font.get(c,font[' '])

            for gy,row in enumerate(glyph):
                for gx,on in enumerate(row):
                    if on!='1':
                        continue

                    for dy in range(scale):
                        for dx in range(scale):
                            xx=x0+ci*cw+gx*scale+dx
                            yy=y0+li*ch+gy*scale+dy

                            if 0<=xx<x and 0<=yy<y:
                                o=yy*stride+xx*4
                                frame[o:o+4]=white

    os.lseek(fd,yo*stride+xo*4,os.SEEK_SET)
    os.write(fd,frame)
    os.fsync(fd)

finally:
    os.close(fd)
PY
}


# ------------------------------------------------------------
# EV_KEY capture
# ------------------------------------------------------------

capture_key()
{
    LABEL="$1"
    CAP="$TMP.capture"

    rm -f "$CAP"

    log "WAIT KEY: $LABEL on $EVENT"

    "$EVTEST" "$EVENT" >"$CAP" 2>/dev/null &
    PID=$!

    sleep 0.10

    show_screen "TSUGARU INPUT SETUP" "PRESS $LABEL" ""

    CODE=""

    while kill -0 "$PID" 2>/dev/null
    do
        CODE=$(
            sed -n \
            's/.*type 1 (EV_KEY), code \([0-9][0-9]*\).*, value 1.*/\1/p' \
            "$CAP" 2>/dev/null |
            head -n1
        )

        if [ -n "$CODE" ]; then
            kill "$PID" 2>/dev/null
            break
        fi

        sleep 0.03
    done

    wait "$PID" 2>/dev/null

    case "$CODE" in
        ''|*[!0-9]*)
            log "ERROR: $LABEL capture failed"
            return 1
            ;;
    esac

    log "$LABEL KEY CODE=$CODE"

    show_screen "TSUGARU INPUT SETUP" "$LABEL OK" "CODE $CODE"
    sleep 0.5

    printf '%s' "$CODE"
}


# ------------------------------------------------------------
# D-PAD capture
#
# Output:
# KEY:code:value
# ABS:code:value
# ------------------------------------------------------------

capture_direction()
{
    LABEL="$1"
    CAP="$TMP.capture"

    rm -f "$CAP"

    log "WAIT DIRECTION: $LABEL on $EVENT"

    "$EVTEST" "$EVENT" >"$CAP" 2>/dev/null &
    PID=$!

    sleep 0.10

    show_screen "TSUGARU INPUT SETUP" "PRESS $LABEL" ""

    RESULT=""

    while kill -0 "$PID" 2>/dev/null
    do
        # First accept EV_KEY press.
        LINE=$(
            sed -n \
            's/.*type 1 (EV_KEY), code \([0-9][0-9]*\).*, value 1.*/KEY:\1:1/p' \
            "$CAP" 2>/dev/null |
            head -n1
        )

        if [ -n "$LINE" ]; then
            RESULT="$LINE"
            kill "$PID" 2>/dev/null
            break
        fi

        # Then look for non-zero EV_ABS movement.
        LINE=$(
            sed -n \
            's/.*type 3 (EV_ABS), code \([0-9][0-9]*\).*, value \(-\{0,1\}[0-9][0-9]*\).*/ABS:\1:\2/p' \
            "$CAP" 2>/dev/null |
            awk -F: '$3 != 0 {print; exit}'
        )

        if [ -n "$LINE" ]; then
            RESULT="$LINE"
            kill "$PID" 2>/dev/null
            break
        fi

        sleep 0.03
    done

    wait "$PID" 2>/dev/null

    if [ -z "$RESULT" ]; then
        log "ERROR: $LABEL direction capture failed"
        return 1
    fi

    TYPE=$(printf '%s' "$RESULT" | cut -d: -f1)
    CODE=$(printf '%s' "$RESULT" | cut -d: -f2)
    VALUE=$(printf '%s' "$RESULT" | cut -d: -f3)

    log "$LABEL TYPE=$TYPE CODE=$CODE VALUE=$VALUE"

    show_screen "TSUGARU INPUT SETUP" "$LABEL OK" "CODE $CODE"
    sleep 0.5

    printf '%s' "$RESULT"
}


# ------------------------------------------------------------
# Controller discovery using SELECT
# ------------------------------------------------------------

CANDIDATES=""
OTHERS=""
COUNT=0

log "Controller discovery started."

for DEV in /dev/input/event*
do
    [ -e "$DEV" ] || continue

    NAME=$(cat "/sys/class/input/$(basename "$DEV")/device/name" 2>/dev/null)

    log "DEVICE: $DEV NAME: ${NAME:-unknown}"

    case "$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')" in
        *gamepad*|*joystick*|*controller*)
            CANDIDATES="$CANDIDATES $DEV"
            COUNT=$((COUNT+1))
            ;;
        *)
            OTHERS="$OTHERS $DEV"
            ;;
    esac
done

EVENT=""
SELECT_CODE=""

if [ "$COUNT" -eq 1 ]; then

    for DEV in $CANDIDATES
    do
        EVENT="$DEV"
    done

    log "AUTO CANDIDATE: $EVENT"

    rm -f "$TMP"

    "$EVTEST" "$EVENT" >"$TMP" 2>/dev/null &
    PID=$!

    sleep 0.10

    show_screen "TSUGARU INPUT SETUP" "PRESS SELECT" ""

    while kill -0 "$PID" 2>/dev/null
    do
        SELECT_CODE=$(
            sed -n \
            's/.*type 1 (EV_KEY), code \([0-9][0-9]*\).*, value 1.*/\1/p' \
            "$TMP" 2>/dev/null |
            head -n1
        )

        if [ -n "$SELECT_CODE" ]; then
            kill "$PID" 2>/dev/null
            break
        fi

        sleep 0.03
    done

    wait "$PID" 2>/dev/null

else

    show_screen "TSUGARU INPUT SETUP" "PRESS SELECT" "REPEATEDLY"

    for DEV in $CANDIDATES $OTHERS
    do
        log "SCAN: $DEV"

        rm -f "$TMP"

        timeout 4 "$EVTEST" "$DEV" >"$TMP" 2>/dev/null &
        PID=$!

        FOUND=""

        while kill -0 "$PID" 2>/dev/null
        do
            FOUND=$(
                sed -n \
                's/.*type 1 (EV_KEY), code \([0-9][0-9]*\).*, value 1.*/\1/p' \
                "$TMP" 2>/dev/null |
                head -n1
            )

            if [ -n "$FOUND" ]; then
                kill "$PID" 2>/dev/null
                break
            fi

            sleep 0.05
        done

        wait "$PID" 2>/dev/null

        if [ -n "$FOUND" ]; then
            EVENT="$DEV"
            SELECT_CODE="$FOUND"
            break
        fi
    done
fi


if [ -z "$EVENT" ] || [ -z "$SELECT_CODE" ]; then
    log "ERROR: controller not detected"
    show_screen "TSUGARU INPUT SETUP" "ERROR" "NO CONTROLLER"
    sleep 4
    exit 1
fi

log "EVENT=$EVENT"
log "SELECT=$SELECT_CODE"

show_screen "TSUGARU INPUT SETUP" "SELECT OK" "CODE $SELECT_CODE"
sleep 0.5


# ------------------------------------------------------------
# D-PAD
# ------------------------------------------------------------

UP_RESULT=$(capture_direction UP) || exit 1
DOWN_RESULT=$(capture_direction DOWN) || exit 1
LEFT_RESULT=$(capture_direction LEFT) || exit 1
RIGHT_RESULT=$(capture_direction RIGHT) || exit 1

UP_TYPE=$(printf '%s' "$UP_RESULT" | cut -d: -f1)
DOWN_TYPE=$(printf '%s' "$DOWN_RESULT" | cut -d: -f1)
LEFT_TYPE=$(printf '%s' "$LEFT_RESULT" | cut -d: -f1)
RIGHT_TYPE=$(printf '%s' "$RIGHT_RESULT" | cut -d: -f1)

UP_CODE=$(printf '%s' "$UP_RESULT" | cut -d: -f2)
DOWN_CODE=$(printf '%s' "$DOWN_RESULT" | cut -d: -f2)
LEFT_CODE=$(printf '%s' "$LEFT_RESULT" | cut -d: -f2)
RIGHT_CODE=$(printf '%s' "$RIGHT_RESULT" | cut -d: -f2)

UP_VALUE=$(printf '%s' "$UP_RESULT" | cut -d: -f3)
DOWN_VALUE=$(printf '%s' "$DOWN_RESULT" | cut -d: -f3)
LEFT_VALUE=$(printf '%s' "$LEFT_RESULT" | cut -d: -f3)
RIGHT_VALUE=$(printf '%s' "$RIGHT_RESULT" | cut -d: -f3)


# ------------------------------------------------------------
# Determine D-PAD type
# ------------------------------------------------------------

DPAD_TYPE=""

if [ "$UP_TYPE" = "ABS" ] &&
   [ "$DOWN_TYPE" = "ABS" ] &&
   [ "$LEFT_TYPE" = "ABS" ] &&
   [ "$RIGHT_TYPE" = "ABS" ]; then

    DPAD_TYPE="ABS"

elif [ "$UP_TYPE" = "KEY" ] &&
     [ "$DOWN_TYPE" = "KEY" ] &&
     [ "$LEFT_TYPE" = "KEY" ] &&
     [ "$RIGHT_TYPE" = "KEY" ]; then

    DPAD_TYPE="KEY"

else
    log "ERROR: mixed D-PAD event types"
    log "UP=$UP_RESULT"
    log "DOWN=$DOWN_RESULT"
    log "LEFT=$LEFT_RESULT"
    log "RIGHT=$RIGHT_RESULT"

    show_screen "TSUGARU INPUT SETUP" "ERROR" "MIXED DPAD TYPE"
    sleep 5
    exit 1
fi


# ------------------------------------------------------------
# Analyze ABS D-PAD
# ------------------------------------------------------------

if [ "$DPAD_TYPE" = "ABS" ]; then

    # UP and DOWN must use same axis.
    if [ "$UP_CODE" != "$DOWN_CODE" ]; then
        log "ERROR: UP/DOWN use different ABS axes"
        show_screen "TSUGARU INPUT SETUP" "ERROR" "UP DOWN AXIS"
        sleep 5
        exit 1
    fi

    # LEFT and RIGHT must use same axis.
    if [ "$LEFT_CODE" != "$RIGHT_CODE" ]; then
        log "ERROR: LEFT/RIGHT use different ABS axes"
        show_screen "TSUGARU INPUT SETUP" "ERROR" "LEFT RIGHT AXIS"
        sleep 5
        exit 1
    fi

    # Horizontal and vertical axes must differ.
    if [ "$LEFT_CODE" = "$UP_CODE" ]; then
        log "ERROR: X and Y use same ABS axis"
        show_screen "TSUGARU INPUT SETUP" "ERROR" "SAME XY AXIS"
        sleep 5
        exit 1
    fi

    DPAD_X_CODE="$LEFT_CODE"
    DPAD_Y_CODE="$UP_CODE"

    # LEFT and RIGHT must have opposite signs.
    if [ "$LEFT_VALUE" -lt 0 ] && [ "$RIGHT_VALUE" -gt 0 ]; then
        DPAD_X_REVERSE=0
    elif [ "$LEFT_VALUE" -gt 0 ] && [ "$RIGHT_VALUE" -lt 0 ]; then
        DPAD_X_REVERSE=1
    else
        log "ERROR: invalid LEFT/RIGHT ABS values"
        log "LEFT_VALUE=$LEFT_VALUE RIGHT_VALUE=$RIGHT_VALUE"
        show_screen "TSUGARU INPUT SETUP" "ERROR" "X AXIS VALUES"
        sleep 5
        exit 1
    fi

    # UP and DOWN must have opposite signs.
    if [ "$UP_VALUE" -lt 0 ] && [ "$DOWN_VALUE" -gt 0 ]; then
        DPAD_Y_REVERSE=0
    elif [ "$UP_VALUE" -gt 0 ] && [ "$DOWN_VALUE" -lt 0 ]; then
        DPAD_Y_REVERSE=1
    else
        log "ERROR: invalid UP/DOWN ABS values"
        log "UP_VALUE=$UP_VALUE DOWN_VALUE=$DOWN_VALUE"
        show_screen "TSUGARU INPUT SETUP" "ERROR" "Y AXIS VALUES"
        sleep 5
        exit 1
    fi

    log "DPAD_TYPE=ABS"
    log "DPAD_X_CODE=$DPAD_X_CODE"
    log "DPAD_Y_CODE=$DPAD_Y_CODE"
    log "DPAD_X_REVERSE=$DPAD_X_REVERSE"
    log "DPAD_Y_REVERSE=$DPAD_Y_REVERSE"
fi


# ------------------------------------------------------------
# Analyze KEY D-PAD
# ------------------------------------------------------------

if [ "$DPAD_TYPE" = "KEY" ]; then

    DPAD_UP_CODE="$UP_CODE"
    DPAD_DOWN_CODE="$DOWN_CODE"
    DPAD_LEFT_CODE="$LEFT_CODE"
    DPAD_RIGHT_CODE="$RIGHT_CODE"

    DIRECTION_CODES="$DPAD_UP_CODE $DPAD_DOWN_CODE $DPAD_LEFT_CODE $DPAD_RIGHT_CODE"

    DIRECTION_UNIQUE=$(
        printf '%s\n' $DIRECTION_CODES |
        sort -n -u |
        wc -l
    )

    if [ "$DIRECTION_UNIQUE" -ne 4 ]; then
        log "ERROR: duplicate D-PAD KEY codes: $DIRECTION_CODES"
        show_screen "TSUGARU INPUT SETUP" "ERROR" "DUPLICATE DPAD"
        sleep 5
        exit 1
    fi

    log "DPAD_TYPE=KEY"
    log "DPAD_UP_CODE=$DPAD_UP_CODE"
    log "DPAD_DOWN_CODE=$DPAD_DOWN_CODE"
    log "DPAD_LEFT_CODE=$DPAD_LEFT_CODE"
    log "DPAD_RIGHT_CODE=$DPAD_RIGHT_CODE"
fi


# ------------------------------------------------------------
# Normal buttons
# ------------------------------------------------------------

A_CODE=$(capture_key A) || exit 1
B_CODE=$(capture_key B) || exit 1
START_CODE=$(capture_key START) || exit 1
L1_CODE=$(capture_key L1) || exit 1
R1_CODE=$(capture_key R1) || exit 1
L2_CODE=$(capture_key L2) || exit 1
R2_CODE=$(capture_key R2) || exit 1


# ------------------------------------------------------------
# Validate button codes
# ------------------------------------------------------------

BUTTON_CODES="$SELECT_CODE $A_CODE $B_CODE $START_CODE $L1_CODE $R1_CODE $L2_CODE $R2_CODE"

BUTTON_UNIQUE=$(
    printf '%s\n' $BUTTON_CODES |
    sort -n -u |
    wc -l
)

if [ "$BUTTON_UNIQUE" -ne 8 ]; then
    log "ERROR: duplicate button codes: $BUTTON_CODES"
    show_screen "TSUGARU INPUT SETUP" "ERROR" "DUPLICATE CODE"
    sleep 5
    exit 1
fi


# For KEY-type D-PAD, make sure D-PAD codes do not collide
# with the action/launcher buttons.

if [ "$DPAD_TYPE" = "KEY" ]; then

    ALL_KEY_CODES="$BUTTON_CODES $DPAD_UP_CODE $DPAD_DOWN_CODE $DPAD_LEFT_CODE $DPAD_RIGHT_CODE"

    ALL_KEY_UNIQUE=$(
        printf '%s\n' $ALL_KEY_CODES |
        sort -n -u |
        wc -l
    )

    if [ "$ALL_KEY_UNIQUE" -ne 12 ]; then
        log "ERROR: KEY D-PAD collides with button code"
        log "CODES: $ALL_KEY_CODES"
        show_screen "TSUGARU INPUT SETUP" "ERROR" "KEY CODE COLLISION"
        sleep 5
        exit 1
    fi
fi


# ------------------------------------------------------------
# Create new input.cfg
# ------------------------------------------------------------

{
    echo "# Tsugaru launcher input configuration"
    echo "EVENT=\"$EVENT\""
    echo
    echo "A_CODE=$A_CODE"
    echo "B_CODE=$B_CODE"
    echo "SELECT_CODE=$SELECT_CODE"
    echo "START_CODE=$START_CODE"
    echo
    echo "L1_CODE=$L1_CODE"
    echo "R1_CODE=$R1_CODE"
    echo "L2_CODE=$L2_CODE"
    echo "R2_CODE=$R2_CODE"
    echo
    echo "DPAD_TYPE=$DPAD_TYPE"

    if [ "$DPAD_TYPE" = "ABS" ]; then
        echo "DPAD_X_CODE=$DPAD_X_CODE"
        echo "DPAD_Y_CODE=$DPAD_Y_CODE"
        echo "DPAD_X_REVERSE=$DPAD_X_REVERSE"
        echo "DPAD_Y_REVERSE=$DPAD_Y_REVERSE"
    else
        echo "DPAD_UP_CODE=$DPAD_UP_CODE"
        echo "DPAD_DOWN_CODE=$DPAD_DOWN_CODE"
        echo "DPAD_LEFT_CODE=$DPAD_LEFT_CODE"
        echo "DPAD_RIGHT_CODE=$DPAD_RIGHT_CODE"
    fi

} >"$NEWCFG"


# ------------------------------------------------------------
# Validate generated cfg
# ------------------------------------------------------------

grep -q '^EVENT="/dev/input/event[0-9][0-9]*"$' "$NEWCFG" || {
    log "ERROR: EVENT validation failed"
    exit 1
}

for K in A_CODE B_CODE SELECT_CODE START_CODE L1_CODE R1_CODE L2_CODE R2_CODE
do
    grep -Eq "^${K}=[0-9]+$" "$NEWCFG" || {
        log "ERROR: $K validation failed"
        exit 1
    }
done

grep -Eq '^DPAD_TYPE=(ABS|KEY)$' "$NEWCFG" || {
    log "ERROR: DPAD_TYPE validation failed"
    exit 1
}


if [ "$DPAD_TYPE" = "ABS" ]; then

    for K in DPAD_X_CODE DPAD_Y_CODE
    do
        grep -Eq "^${K}=[0-9]+$" "$NEWCFG" || {
            log "ERROR: $K validation failed"
            exit 1
        }
    done

    for K in DPAD_X_REVERSE DPAD_Y_REVERSE
    do
        grep -Eq "^${K}=[01]$" "$NEWCFG" || {
            log "ERROR: $K validation failed"
            exit 1
        }
    done

else

    for K in DPAD_UP_CODE DPAD_DOWN_CODE DPAD_LEFT_CODE DPAD_RIGHT_CODE
    do
        grep -Eq "^${K}=[0-9]+$" "$NEWCFG" || {
            log "ERROR: $K validation failed"
            exit 1
        }
    done
fi


# ------------------------------------------------------------
# Backup old cfg and install new cfg
# ------------------------------------------------------------

if [ -f "$OUTPUT" ]; then

    cp -f "$OUTPUT" "$BACKUP" || {
        log "ERROR: backup failed"
        show_screen "TSUGARU INPUT SETUP" "ERROR" "BACKUP FAILED"
        sleep 4
        exit 1
    }
fi


mv -f "$NEWCFG" "$OUTPUT" || {
    log "ERROR: save failed"
    show_screen "TSUGARU INPUT SETUP" "ERROR" "SAVE FAILED"
    sleep 4
    exit 1
}


# ------------------------------------------------------------
# Completed
# ------------------------------------------------------------

log "===== CREATED INPUT.CFG ====="
cat "$OUTPUT" >>"$LOG"

show_screen "SETUP COMPLETED" "INPUT CFG SAVED" "ALL CONTROLS OK"

sleep 5
exit 0
