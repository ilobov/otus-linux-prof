#!/bin/bash
# $1 - log file
# $2 - email address

function last_timestamp {
  local result=$($2 -n 1 $1 | awk '{print $4}' | cut -c 2-)
  echo $result 
}

OUTPUT_FILE=output.txt
LAST_TIMESTAMP_FILE=timestamp.txt

if [ "$1" = "" -o "$2" = "" ] 
then
  echo "Need set params"
  exit 1
fi

if [ ! -f $1 ] 
then
  echo "Log file not found"
  exit 1
fi

if [ -f /tmp/myscript.lock ]; then
  echo "Script is already running"
  exit 1
else
  touch /tmp/myscript.lock
fi

NSTR=1
if [ -f $LAST_TIMESTAMP_FILE ]
then
  PREV_LAST_TIMESTAMP=$(cat $LAST_TIMESTAMP_FILE)
  NSTR=$(grep -n $PREV_LAST_TIMESTAMP $1 | tail -n 1 | awk -F ':' '{print $1}')
  NSTR=$((NSTR+1))
else
  PREV_LAST_TIMESTAMP=$(last_timestamp $1 head)
fi
  
tail +$NSTR $1 > temp.log

LAST_TIMESTAMP=$(last_timestamp temp.log tail)

echo $LAST_TIMESTAMP > $LAST_TIMESTAMP_FILE 

echo Period: $PREV_LAST_TIMESTAMP - $LAST_TIMESTAMP > $OUTPUT_FILE

echo >> $OUTPUT_FILE
echo "Top 10 IP address by count of requests" >> $OUTPUT_FILE
echo >> $OUTPUT_FILE

awk '{print $1}' temp.log | sort | uniq -c | sort -n -r | head -n 10 >> $OUTPUT_FILE

echo >> $OUTPUT_FILE
echo "Top 10 URLs by count of requests" >> $OUTPUT_FILE
echo >> $OUTPUT_FILE

grep -P "(GET|POST)" temp.log | awk '{print $7}' | sort | uniq -c | sort -n -r | head -n 10 >> $OUTPUT_FILE

echo >> $OUTPUT_FILE
echo "Errors" >> $OUTPUT_FILE
echo >> $OUTPUT_FILE

grep -P "(ERROR|error)" temp.log >> $OUTPUT_FILE

echo >> $OUTPUT_FILE
echo "Responce codes" >> $OUTPUT_FILE
echo >> $OUTPUT_FILE

grep -P "(GET|POST)" temp.log | awk '{print $9}' | sort | uniq -c | sort -n -r >> $OUTPUT_FILE

cat $OUTPUT_FILE | mail -s "Nginx access log by last hour - $(date)" $2

rm -f /tmp/myscript.lock


