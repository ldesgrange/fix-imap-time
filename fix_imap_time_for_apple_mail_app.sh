#!/bin/sh
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

MDIR_PATH="$1"

if [ $# -lt 1 ]
then
  echo "Usage: $0 /path/to/user/Maildir"
  exit 1
fi
if [ ! -d "$MDIR_PATH" ]
then
  echo "Error: $MDIR_PATH does not exist"
  echo "Usage: $0 /path/to/user/Maildir"
  exit 1
fi
if [ ! -r "$MDIR_PATH" ]
then
  echo "Error: $MDIR_PATH is not readable"
  echo "Usage: $0 /path/to/user/Maildir"
  exit 1
fi
if [ ! -w "$MDIR_PATH" ]
then
  echo "Error: $MDIR_PATH is not writable"
  echo "Usage: $0 /path/to/user/Maildir"
  exit 1
fi

# set the internal field separator to the newline character
# instead of the default "".
# This is required for handling filenames and directories with spaces
IFS="
"
set -f
echo "start"
# Find all emails
for i in `find $MDIR_PATH -type f | egrep -v "(courierimap|maildirsize|maildirfolder)"`
do
  EDATE=`awk '/^Date: [A-Za-z]*,/ {print $4,$3,$5,$6}' "$i" | head -1`
  if [ -z "$EDATE" ]
  then
    continue
  fi
  FDATE=`ls -l --time-style=long-iso "$i" | awk '{print $6,$7}'`
  # Reformat the date for touch.
  NDATE=`date -d "$EDATE" "+%Y%m%d%H%M"`
  ODATE=`date -d "$FDATE" "+%Y%m%d%H%M"`
  if [ "$NDATE" -eq "$ODATE" ]
  then
    # Skip it if the times are correct.
    echo -n "_"
    continue
  fi
  echo `basename $i` "from $ODATE to $NDATE"
  touch -c -t "$NDATE" "$i"
done
echo "done"
