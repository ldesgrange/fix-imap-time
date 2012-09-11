#!/bin/bash
#
# Date : July 4th, 2005
# Author: Benson Wong
# tummytech@gmail.com
#
# This shell script corrects email messages where the file system
# date does not match the Date: header in the email.
#
# This will fix problems with mail clients like Apple's mail.app
# which uses the file system timestamp resulting in emails with the
# wrong file system timestamp to display the wrong received date
#
# This script has to be run by a user [root] with the
# necessary privileges to read/modify files in a user's Maildir.
#

function usage() {
  if [ "$1" != "" ]; then
    echo "$1"
  fi
  echo "Usage: $0 /path/to/user/Maildir"
  exit 1
}

function email_date() {
  local DATELINE=`grep -e "^Date: " "$1" | head -1`
  local DELIVERYDATELINE=`grep -e "^Delivery-date: " "$1" | head -1`
  if [ -n "$DELIVERYDATELINE" ]; then
    local DATELINE="${DELIVERYDATELINE/elivery-d/}"
  fi

  # Fucked up date like Mon, 03 Nov 03 11:37:04 Romance Standard Time
  local regex='^Date: ([A-Za-z]{3}, [0-9]{2} [A-Za-z]{3} [0-9]{2,4} [0-9]{1,2}:[0-9]{2}:[0-9]{2}) ([A-Za-z ]*)$'
  if [[ $DATELINE =~ $regex ]]; then
    EDATE=`date -d "${BASH_REMATCH[1]}" "+%Y%m%d%H%M"`
    return 0
  fi

  # Missing "+" before timezone
  local regex='^Date: ([A-Za-z]*, [0-9]* [A-Za-z]* [0-9]{4} [0-9]{1,2}:[0-9]{2}:[0-9]{2}) ([0-9]{4})$'
  if [[ $DATELINE =~ $regex ]]; then
    EDATE=`date -d "${BASH_REMATCH[1]} +${BASH_REMATCH[2]}" "+%Y%m%d%H%M"`
    return 0
  fi

  local regex='^Date: (.*)$'
  if [[ $DATELINE =~ $regex ]]; then
    EDATE=`date -d "${BASH_REMATCH[1]}" "+%Y%m%d%H%M"`
    return 0
  fi
}

MDIR_PATH="$1"

[ $# -lt 1 ] && usage
[ ! -d "$MDIR_PATH" ] && usage "Error: $MDIR_PATH does not exist"
[ ! -r "$MDIR_PATH" ] && usage "Error: $MDIR_PATH is not readable"
[ ! -w "$MDIR_PATH" ] && usage "Error: $MDIR_PATH is not writable"

# set the internal field separator to the newline character
# instead of the default "".
# This is required for handling filenames and directories with spaces
IFS="
"
set -f
echo "start"
# Find all emails
for i in `find $MDIR_PATH -type f | egrep -v "(courierimap|maildirsize|maildirfolder)"`; do
  email_date "$i"
  if [ -z "$EDATE" ]; then
    echo ""
    echo "Unparsable date for" `basename $i`
    continue
  fi
  FDATE=`ls -l --time-style=long-iso "$i" | awk '{print $6,$7}'`
  # Reformat the date for touch.
  ODATE=`date -d "$FDATE" "+%Y%m%d%H%M"`
  if [ "$EDATE" -eq "$ODATE" ]; then
    # Skip it if the times are correct.
    echo -n "."
    continue
  fi
  echo ""
  echo `basename $i` "from $ODATE to $EDATE"
  touch -c -t "$EDATE" "$i"
done

echo ""
echo "done"
