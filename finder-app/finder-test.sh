#!/bin/sh
# Tester script for assignment 1 and assignment 2
# Author: Siddhant Jajoo

set -e
set -u

NUMFILES=10
WRITESTR=AELD_IS_FUN
WRITEDIR=/tmp/aeld-data
WRITEFILE4="/tmp/assignment4-result.txt"
if [ -d "/etc/finder-app" ]; then
	username=$(cat /etc/finder-app/conf/username.txt)
else
	username=$(cat conf/username.txt)
fi

if [ $# -lt 3 ]
then
	echo "Using default value ${WRITESTR} for string to write"
	if [ $# -lt 1 ]
	then
		echo "Using default value ${NUMFILES} for number of files to write"
	else
		NUMFILES=$1
	fi	
else
	NUMFILES=$1
	WRITESTR=$2
	WRITEDIR=/tmp/aeld-data/$3
fi

MATCHSTR="The number of files are ${NUMFILES} and the number of matching lines are ${NUMFILES}"

echo "Writing ${NUMFILES} files containing string ${WRITESTR} to ${WRITEDIR}"

rm -rf "${WRITEDIR}"

# create $WRITEDIR if not assignment1
if [ -d "/etc/finder-app" ]; then
	assignment=`cat /etc/finder-app/conf/assignment.txt`
else
	assignment=`cat ../conf/assignment.txt`
fi

if [ $assignment != 'assignment1' ]
then
	mkdir -p "$WRITEDIR"

	#The WRITEDIR is in quotes because if the directory path consists of spaces, then variable substitution will consider it as multiple argument.
	#The quotes signify that the entire string in WRITEDIR is a single string.
	#This issue can also be resolved by using double square brackets i.e [[ ]] instead of using quotes.
	if [ -d "$WRITEDIR" ]
	then
		echo "$WRITEDIR created"
	else
		exit 1
	fi
fi

#echo "Removing the old writer utility and compiling as a native application"
#make clean
#make

for i in $( seq 1 $NUMFILES)
do
	if [ -d "/etc/finder-app" ]; then
		writer "$WRITEFILE4" "$WRITESTR"
	else
		./writer "$WRITEDIR/${username}$i.txt" "$WRITESTR"
	fi
done

if [ -d "/etc/finder-app" ]; then
	OUTPUTSTRING=$(finder.sh "$WRITEFILE4" "$WRITESTR")
else
	OUTPUTSTRING=$(./finder.sh "$WRITEDIR" "$WRITESTR")
fi

# remove temporary directories
rm -rf /tmp/aeld-data

set +e
echo ${OUTPUTSTRING} | grep "${MATCHSTR}"
if [ $? -eq 0 ]; then
	echo "success"
	exit 0
else
	echo "failed: expected  ${MATCHSTR} in ${OUTPUTSTRING} but instead found"
	exit 1
fi
