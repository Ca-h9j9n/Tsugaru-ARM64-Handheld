#!/bin/bash

TSUGARU="/userdata/system/tsugaru/Tsugaru_CUI_V90S"
BIOS="/userdata/bios/fmtowns"
CMOS="/userdata/system/tsugaru/cmos.dat"
TSU_FILE="$1"
LOG="/userdata/system/tsugaru/launch_fmtowns.log"

CMD_FIFO="/tmp/tsugaru_cmd"
INPUT_FIFO="/tmp/tsugaru_input"

INPUT_CFG="/userdata/system/tsugaru/input.cfg"
EVTEST="/usr/bin/evtest"

# V90S fallback values
EVENT="/dev/input/event4"
SELECT_CODE=314
START_CODE=315
L1_CODE=310
R1_CODE=311
L2_CODE=312
R2_CODE=313

# Load input.cfg if present.
if [ -f "$INPUT_CFG" ]; then
    . "$INPUT_CFG"
fi

EVTEST_PID=""
MONITOR_PID=""

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

log()
{
    echo "$1" >> "$LOG"
}

: > "$LOG"

log "===== TSUGARU GENERIC INPUT LAUNCHER ====="
log "PID: $$"
log "PPID: $PPID"
log "TSU: $TSU_FILE"
log "CMOS: $CMOS"
log "CMD FIFO: $CMD_FIFO"
log "INPUT FIFO: $INPUT_FIFO"
if [ -f "$INPUT_CFG" ]; then
    log "INPUT CFG: loaded $INPUT_CFG"
else
    log "INPUT CFG: not found - using V90S fallback"
fi
log "INPUT EVENT: $EVENT"
log "SELECT: $SELECT_CODE"
log "START: $START_CODE"
log "L1: $L1_CODE"
log "R1: $R1_CODE"
log "L2: $L2_CODE"
log "R2: $R2_CODE"
log "STEP 1: launcher started"

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

cleanup()
{
    log "CLEANUP: starting"

    if [ -n "$EVTEST_PID" ]; then

        if kill -0 "$EVTEST_PID" 2>/dev/null; then

            log "CLEANUP: stopping evtest PID $EVTEST_PID"

            kill "$EVTEST_PID" 2>/dev/null
            sleep 1

            if kill -0 "$EVTEST_PID" 2>/dev/null; then
                log "CLEANUP: evtest still running - sending KILL"
                kill -9 "$EVTEST_PID" 2>/dev/null
            fi
        fi

        wait "$EVTEST_PID" 2>/dev/null
        log "CLEANUP: evtest stopped"

        EVTEST_PID=""
    fi

    if [ -n "$MONITOR_PID" ]; then

        if kill -0 "$MONITOR_PID" 2>/dev/null; then

            log "CLEANUP: stopping monitor PID $MONITOR_PID"

            kill "$MONITOR_PID" 2>/dev/null
            sleep 1

            if kill -0 "$MONITOR_PID" 2>/dev/null; then
                log "CLEANUP: monitor still running - sending KILL"
                kill -9 "$MONITOR_PID" 2>/dev/null
            fi
        fi

        wait "$MONITOR_PID" 2>/dev/null
        log "CLEANUP: monitor stopped"

        MONITOR_PID=""
    fi

    exec 3>&- 2>/dev/null

    rm -f "$CMD_FIFO"
    rm -f "$INPUT_FIFO"

    log "CLEANUP: FIFOs removed"
    log "CLEANUP: completed"
}

trap cleanup EXIT INT TERM

# ------------------------------------------------------------
# Basic checks
# ------------------------------------------------------------

if [ ! -x "$TSUGARU" ]; then
    log "ERROR: Tsugaru executable not found."
    exit 1
fi

log "STEP 2: Tsugaru executable OK"

if [ -z "$TSU_FILE" ]; then
    log "ERROR: TSU file not specified."
    exit 1
fi

if [ ! -f "$TSU_FILE" ]; then
    log "ERROR: TSU file not found."
    exit 1
fi

log "STEP 3: TSU file OK"

if [ ! -e "$EVENT" ]; then
    log "ERROR: $EVENT not found."
    exit 1
fi

if [ ! -x "$EVTEST" ]; then
    log "ERROR: evtest not found."
    exit 1
fi

log "STEP 4: input device OK"

# ------------------------------------------------------------
# Game directory
# ------------------------------------------------------------

GAME_DIR="${TSU_FILE%/*}"

log "STEP 5: GAME_DIR calculated"
log "GAME_DIR: $GAME_DIR"

if ! cd "$GAME_DIR"; then
    log "ERROR: cd failed."
    exit 1
fi

log "STEP 6: cd completed"

# ------------------------------------------------------------
# Read TSU
#
# Normal Tsugaru:
# -CD "disc1.cue"
# -FD0 "disk1.hdm"
# -FD1 "disk2.hdm"
#
# Launcher-only:
# -CDNEXT "disc2.cue"
# -FD0NEXT "disk3.hdm"
# -FD1NEXT "disk4.hdm"
# ------------------------------------------------------------

ARGS=()
CD_LIST=()
FD0_LIST=()
FD1_LIST=()

LINE_NUMBER=0

log "STEP 7: TSU read start"

while IFS= read -r LINE || [ -n "$LINE" ]; do

    LINE_NUMBER=$((LINE_NUMBER + 1))

    LINE="${LINE%$'\r'}"

    [ -z "$LINE" ] && continue

    case "$LINE" in
        \#*) continue ;;
    esac

    OPTION="${LINE%%[[:space:]]*}"

    VALUE="${LINE#"$OPTION"}"
    VALUE="${VALUE#"${VALUE%%[![:space:]]*}"}"

    case "$VALUE" in
        \"*\")
            VALUE="${VALUE#\"}"
            VALUE="${VALUE%\"}"
            ;;
    esac

    if [ -z "$OPTION" ] || [ -z "$VALUE" ]; then
        log "ERROR: invalid TSU line $LINE_NUMBER"
        exit 1
    fi

    # --------------------------------------------------------
    # Launcher-only CD
    # --------------------------------------------------------

    if [ "$OPTION" = "-CDNEXT" ]; then

        CD_LIST+=("$VALUE")
        log "CD LIST: added $VALUE"

        continue
    fi

    # --------------------------------------------------------
    # Launcher-only FD0
    # --------------------------------------------------------

    if [ "$OPTION" = "-FD0NEXT" ]; then

        FD0_LIST+=("$VALUE")
        log "FD0 LIST: added $VALUE"

        continue
    fi

    # --------------------------------------------------------
    # Launcher-only FD1
    # --------------------------------------------------------

    if [ "$OPTION" = "-FD1NEXT" ]; then

        FD1_LIST+=("$VALUE")
        log "FD1 LIST: added $VALUE"

        continue
    fi

    # --------------------------------------------------------
    # Initial CD
    # --------------------------------------------------------

    if [ "$OPTION" = "-CD" ]; then
        CD_LIST+=("$VALUE")
    fi

    # --------------------------------------------------------
    # Initial FD0
    # --------------------------------------------------------

    if [ "$OPTION" = "-FD0" ]; then
        FD0_LIST+=("$VALUE")
    fi

    # --------------------------------------------------------
    # Initial FD1
    # --------------------------------------------------------

    if [ "$OPTION" = "-FD1" ]; then
        FD1_LIST+=("$VALUE")
    fi

    # --------------------------------------------------------
    # Normal Tsugaru argument
    # --------------------------------------------------------

    ARGS+=("$OPTION")
    ARGS+=("$VALUE")

done < "$TSU_FILE"

log "STEP 8: TSU read completed"

if [ ${#ARGS[@]} -eq 0 ]; then
    log "ERROR: no arguments."
    exit 1
fi

log "STEP 9: arguments OK"

INDEX=0

for ARG in "${ARGS[@]}"; do
    printf 'ARG[%d]=[%s]\n' "$INDEX" "$ARG" >> "$LOG"
    INDEX=$((INDEX + 1))
done

# ------------------------------------------------------------
# CD information
# ------------------------------------------------------------

CD_COUNT=${#CD_LIST[@]}

log "CD COUNT: $CD_COUNT"

INDEX=0

for CD in "${CD_LIST[@]}"; do

    printf 'CD[%d]=[%s]\n' "$INDEX" "$CD" >> "$LOG"

    if [ ! -f "$CD" ]; then
        log "ERROR: CD file not found: $CD"
        exit 1
    fi

    INDEX=$((INDEX + 1))
done

if [ "$CD_COUNT" -gt 0 ]; then
    log "CURRENT CD: 1 / $CD_COUNT"
fi

# ------------------------------------------------------------
# FD0 information
# ------------------------------------------------------------

FD0_COUNT=${#FD0_LIST[@]}

log "FD0 COUNT: $FD0_COUNT"

INDEX=0

for FD in "${FD0_LIST[@]}"; do

    printf 'FD0[%d]=[%s]\n' "$INDEX" "$FD" >> "$LOG"

    if [ ! -f "$FD" ]; then
        log "ERROR: FD0 file not found: $FD"
        exit 1
    fi

    INDEX=$((INDEX + 1))
done

if [ "$FD0_COUNT" -gt 0 ]; then
    log "CURRENT FD0: 1 / $FD0_COUNT"
fi

# ------------------------------------------------------------
# FD1 information
# ------------------------------------------------------------

FD1_COUNT=${#FD1_LIST[@]}

log "FD1 COUNT: $FD1_COUNT"

INDEX=0

for FD in "${FD1_LIST[@]}"; do

    printf 'FD1[%d]=[%s]\n' "$INDEX" "$FD" >> "$LOG"

    if [ ! -f "$FD" ]; then
        log "ERROR: FD1 file not found: $FD"
        exit 1
    fi

    INDEX=$((INDEX + 1))
done

if [ "$FD1_COUNT" -gt 0 ]; then
    log "CURRENT FD1: 1 / $FD1_COUNT"
fi

# ------------------------------------------------------------
# CMOS
# ------------------------------------------------------------

if [ -f "$CMOS" ]; then
    log "CMOS STATUS BEFORE: existing cmos.dat"
else
    log "CMOS STATUS BEFORE: cmos.dat not found"
fi

# ------------------------------------------------------------
# Command FIFO
# ------------------------------------------------------------

log "STEP 10: preparing command FIFO"

rm -f "$CMD_FIFO"

if ! mkfifo "$CMD_FIFO"; then
    log "ERROR: cannot create command FIFO."
    exit 1
fi

if ! exec 3<> "$CMD_FIFO"; then
    log "ERROR: cannot open command FIFO."
    exit 1
fi

log "CMD FIFO STATUS: ready"

# ------------------------------------------------------------
# Input FIFO
# ------------------------------------------------------------

log "STEP 11: preparing input FIFO"

rm -f "$INPUT_FIFO"

if ! mkfifo "$INPUT_FIFO"; then
    log "ERROR: cannot create input FIFO."
    exit 1
fi

log "INPUT FIFO STATUS: created"

# ------------------------------------------------------------
# Button monitor
# ------------------------------------------------------------

log "STEP 12: starting button monitor"

(
    SELECT_DOWN=0
    START_DOWN=0
    L1_DOWN=0
    R1_DOWN=0
    L2_DOWN=0
    R2_DOWN=0

    QUIT_SENT=0

    CURRENT_CD=0
    CURRENT_FD0=0
    CURRENT_FD1=0

    while IFS= read -r LINE; do

        # ====================================================
        # Update button states
        # ====================================================

        case "$LINE" in

            *"type 1 (EV_KEY), code $SELECT_CODE "*" value 1"*)
                SELECT_DOWN=1
                log "INPUT: SELECT DOWN"
                ;;

            *"type 1 (EV_KEY), code $SELECT_CODE "*" value 0"*)
                SELECT_DOWN=0
                log "INPUT: SELECT UP"
                ;;

            *"type 1 (EV_KEY), code $START_CODE "*" value 1"*)
                START_DOWN=1
                log "INPUT: START DOWN"
                ;;

            *"type 1 (EV_KEY), code $START_CODE "*" value 0"*)
                START_DOWN=0
                log "INPUT: START UP"
                ;;

            *"type 1 (EV_KEY), code $L1_CODE "*" value 1"*)
                L1_DOWN=1
                log "INPUT: L1 DOWN"
                ;;

            *"type 1 (EV_KEY), code $L1_CODE "*" value 0"*)
                L1_DOWN=0
                log "INPUT: L1 UP"
                ;;

            *"type 1 (EV_KEY), code $R1_CODE "*" value 1"*)
                R1_DOWN=1
                log "INPUT: R1 DOWN"
                ;;

            *"type 1 (EV_KEY), code $R1_CODE "*" value 0"*)
                R1_DOWN=0
                log "INPUT: R1 UP"
                ;;

            *"type 1 (EV_KEY), code $L2_CODE "*" value 1"*)
                L2_DOWN=1
                log "INPUT: L2 DOWN"
                ;;

            *"type 1 (EV_KEY), code $L2_CODE "*" value 0"*)
                L2_DOWN=0
                log "INPUT: L2 UP"
                ;;

            *"type 1 (EV_KEY), code $R2_CODE "*" value 1"*)
                R2_DOWN=1
                log "INPUT: R2 DOWN"
                ;;

            *"type 1 (EV_KEY), code $R2_CODE "*" value 0"*)
                R2_DOWN=0
                log "INPUT: R2 UP"
                ;;

        esac

        # ====================================================
        # SELECT + START
        # Quit Tsugaru
        # ====================================================

        if [ "$SELECT_DOWN" -eq 1 ] &&
           [ "$START_DOWN" -eq 1 ] &&
           [ "$QUIT_SENT" -eq 0 ]; then

            log "HOTKEY: SELECT+START detected"
            log "HOTKEY: sending Q to Tsugaru"

            if printf '%s\n' "Q" >&3; then
                log "HOTKEY: Q written to FIFO"
                QUIT_SENT=1
            else
                log "ERROR: Q write failed"
            fi
        fi

        # ====================================================
        # SELECT + R1
        # Next CD
        # ====================================================

        case "$LINE" in

            *"type 1 (EV_KEY), code $R1_CODE "*" value 1"*)

                if [ "$SELECT_DOWN" -eq 1 ] &&
                   [ "$CD_COUNT" -gt 1 ]; then

                    CURRENT_CD=$((CURRENT_CD + 1))

                    if [ "$CURRENT_CD" -ge "$CD_COUNT" ]; then
                        CURRENT_CD=0
                    fi

                    NEW_CD="${CD_LIST[$CURRENT_CD]}"

                    log "HOTKEY: SELECT+R1 detected"
                    log "CD: next"
                    log "CD INDEX: $((CURRENT_CD + 1)) / $CD_COUNT"
                    log "CD FILE: $NEW_CD"
                    log "CD COMMAND: CDLOAD $NEW_CD"

                    if printf '%s\n' "CDLOAD $NEW_CD" >&3; then
                        log "CD: command written to FIFO"
                    else
                        log "ERROR: CDLOAD write failed"
                    fi
                fi
                ;;
        esac

        # ====================================================
        # SELECT + L1
        # Previous CD
        # ====================================================

        case "$LINE" in

            *"type 1 (EV_KEY), code $L1_CODE "*" value 1"*)

                if [ "$SELECT_DOWN" -eq 1 ] &&
                   [ "$CD_COUNT" -gt 1 ]; then

                    CURRENT_CD=$((CURRENT_CD - 1))

                    if [ "$CURRENT_CD" -lt 0 ]; then
                        CURRENT_CD=$((CD_COUNT - 1))
                    fi

                    NEW_CD="${CD_LIST[$CURRENT_CD]}"

                    log "HOTKEY: SELECT+L1 detected"
                    log "CD: previous"
                    log "CD INDEX: $((CURRENT_CD + 1)) / $CD_COUNT"
                    log "CD FILE: $NEW_CD"
                    log "CD COMMAND: CDLOAD $NEW_CD"

                    if printf '%s\n' "CDLOAD $NEW_CD" >&3; then
                        log "CD: command written to FIFO"
                    else
                        log "ERROR: CDLOAD write failed"
                    fi
                fi
                ;;
        esac

        # ====================================================
        # SELECT + R2
        # Next FD (FD0 or FD1)
        # ====================================================

        case "$LINE" in

            *"type 1 (EV_KEY), code $R2_CODE "*" value 1"*)

                if [ "$SELECT_DOWN" -eq 1 ]; then

                    if [ "$FD0_COUNT" -gt 1 ]; then

                        CURRENT_FD0=$((CURRENT_FD0 + 1))

                        if [ "$CURRENT_FD0" -ge "$FD0_COUNT" ]; then
                            CURRENT_FD0=0
                        fi

                        NEW_FD="${FD0_LIST[$CURRENT_FD0]}"

                        log "HOTKEY: SELECT+R2 detected"
                        log "FD0: next"
                        log "FD0 INDEX: $((CURRENT_FD0 + 1)) / $FD0_COUNT"
                        log "FD0 FILE: $NEW_FD"
                        log "FD0 COMMAND: FD0LOAD $NEW_FD"

                        if printf '%s\n' "FD0LOAD $NEW_FD" >&3; then
                            log "FD0: command written to FIFO"
                        else
                            log "ERROR: FD0LOAD write failed"
                        fi

                    elif [ "$FD1_COUNT" -gt 1 ]; then

                        CURRENT_FD1=$((CURRENT_FD1 + 1))

                        if [ "$CURRENT_FD1" -ge "$FD1_COUNT" ]; then
                            CURRENT_FD1=0
                        fi

                        NEW_FD="${FD1_LIST[$CURRENT_FD1]}"

                        log "HOTKEY: SELECT+R2 detected"
                        log "FD1: next"
                        log "FD1 INDEX: $((CURRENT_FD1 + 1)) / $FD1_COUNT"
                        log "FD1 FILE: $NEW_FD"
                        log "FD1 COMMAND: FD1LOAD $NEW_FD"

                        if printf '%s\n' "FD1LOAD $NEW_FD" >&3; then
                            log "FD1: command written to FIFO"
                        else
                            log "ERROR: FD1LOAD write failed"
                        fi
                    fi
                fi
                ;;
        esac

        # ====================================================
        # SELECT + L2
        # Previous FD (FD0 or FD1)
        # ====================================================

        case "$LINE" in

            *"type 1 (EV_KEY), code $L2_CODE "*" value 1"*)

                if [ "$SELECT_DOWN" -eq 1 ]; then

                    if [ "$FD0_COUNT" -gt 1 ]; then

                        CURRENT_FD0=$((CURRENT_FD0 - 1))

                        if [ "$CURRENT_FD0" -lt 0 ]; then
                            CURRENT_FD0=$((FD0_COUNT - 1))
                        fi

                        NEW_FD="${FD0_LIST[$CURRENT_FD0]}"

                        log "HOTKEY: SELECT+L2 detected"
                        log "FD0: previous"
                        log "FD0 INDEX: $((CURRENT_FD0 + 1)) / $FD0_COUNT"
                        log "FD0 FILE: $NEW_FD"
                        log "FD0 COMMAND: FD0LOAD $NEW_FD"

                        if printf '%s\n' "FD0LOAD $NEW_FD" >&3; then
                            log "FD0: command written to FIFO"
                        else
                            log "ERROR: FD0LOAD write failed"
                        fi

                    elif [ "$FD1_COUNT" -gt 1 ]; then

                        CURRENT_FD1=$((CURRENT_FD1 - 1))

                        if [ "$CURRENT_FD1" -lt 0 ]; then
                            CURRENT_FD1=$((FD1_COUNT - 1))
                        fi

                        NEW_FD="${FD1_LIST[$CURRENT_FD1]}"

                        log "HOTKEY: SELECT+L2 detected"
                        log "FD1: previous"
                        log "FD1 INDEX: $((CURRENT_FD1 + 1)) / $FD1_COUNT"
                        log "FD1 FILE: $NEW_FD"
                        log "FD1 COMMAND: FD1LOAD $NEW_FD"

                        if printf '%s\n' "FD1LOAD $NEW_FD" >&3; then
                            log "FD1: command written to FIFO"
                        else
                            log "ERROR: FD1LOAD write failed"
                        fi
                    fi
                fi
                ;;
        esac

    done < "$INPUT_FIFO"

    log "MONITOR: input FIFO closed"
    log "MONITOR: exiting"

) &

MONITOR_PID=$!

log "MONITOR PID: $MONITOR_PID"

# ------------------------------------------------------------
# Start evtest
# ------------------------------------------------------------

log "STEP 13: starting evtest"

"$EVTEST" "$EVENT" > "$INPUT_FIFO" 2>&1 &

EVTEST_PID=$!

log "EVTEST PID: $EVTEST_PID"

sleep 1

if ! kill -0 "$EVTEST_PID" 2>/dev/null; then
    log "ERROR: evtest terminated unexpectedly."
    exit 1
fi

log "STEP 14: input system ready"

# ------------------------------------------------------------
# Start Tsugaru
# ------------------------------------------------------------

log "STEP 15: starting Tsugaru"

"$TSUGARU" "$BIOS" \
    -CMOS "$CMOS" \
    -AUTOSCALE \
    -HIGHRES \
    -NOWAITBOOT \
    -GAMEPORT0 KEY \
    -KEYBOARD DIRECT \
    -PAUSEKEY F10 \
    "${ARGS[@]}" \
    <&3

RESULT=$?

# ------------------------------------------------------------
# Tsugaru returned
# ------------------------------------------------------------

log "STEP 16: Tsugaru returned"
log "EXIT CODE: $RESULT"

if [ -f "$CMOS" ]; then
    log "CMOS STATUS AFTER: cmos.dat exists"
else
    log "CMOS STATUS AFTER: cmos.dat NOT found"
fi

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

log "STEP 17: stopping input system"

cleanup

trap - EXIT INT TERM

log "STEP 18: input system stopped"
log "===== END ====="

exit "$RESULT"
