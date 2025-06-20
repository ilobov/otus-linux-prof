#!/bin/bash
echo "    PID TTY      STAT       TIME COMMAND"

function get_tty_name {
if [ "$1" = "0" ]; then
    echo "?"
    exit 0
  fi
  TTY_BIN_MINOR=$(echo "obase=2;$1" | bc | awk '{ print substr($0, length($0)-7) }')
  TTY_BIN_MAJOR=$(echo "obase=2;$1" | bc | awk '{ print substr($0, 0, length($0)-8) }')
  TTY_DEC_MINOR=$(echo "obase=10;ibase=2;$TTY_BIN_MINOR" | bc )
  TTY_DEC_MAJOR=$(echo "obase=10;ibase=2;$TTY_BIN_MAJOR" | bc )

  IFS=$'\n'
  for line in $(cat /proc/tty/drivers | awk -v tty=$TTY_DEC_MAJOR '$3 == tty'); do
    NMIN=$(echo $line | awk '{print $4}' | awk -F- '{ print $1}')
    NMAX=$(echo $line | awk '{print $4}' | awk -F- '{ print $2}')
    if [ -n "$NMAX" ]; then
       if [ "$NMIN" -le "$TTY_DEC_MINOR" -a "$NMAX" -ge "$TTY_DEC_MINOR" ]; then
          RESULT=$(echo $line | awk '{print $2}' | cut -c 6-)$TTY_DEC_MINOR
       fi
    else
       if [ "$NMIN" -eq "$TTY_DEC_MINOR" ]; then
         RESULT=$(echo $line | awk '{print $2}' | cut -c 6-)$TTY_DEC_MINOR
       fi
    fi
  done

 echo $RESULT
}

for i in $(ls -l /proc | grep "^d" | awk '{print $9}')
do
  if [ -f /proc/$i/stat ]; then
    read -r -a stat <<< $(cat "/proc/$i/stat" 2>/dev/null)
    TTY=$(get_tty_name ${stat[6]})
    let clk_tck="$(getconf CLK_TCK)"
    let utime="${stat[13]}"
    let stime="${stat[14]}"
    let cputime=(utime + stime)/clk_tck
    CPUTIME=$(date -d@$cputime -u +%H:%M:%S)
    COMMAND=$(cat /proc/$i/cmdline | tr "\0" " ")
    if [ ! -n "$COMMAND" ]; then
       COMMAND=$(echo "${stat[1]}" | tr "(" "[" | tr ")" "]")
    fi
    printf "%7s %-8s %-5s %9s " $i $TTY ${stat[2]} $CPUTIME; echo $COMMAND
  fi
done
