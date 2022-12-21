#!/bin/bash
# Write a shell script finder-app/finder.sh as described below:
#
# - Accepts the following runtime arguments: the first argument is a path to a
# directory on the filesystem, referred to below as filesdir; the second
# argument is a text string which will be searched within these files, referred
# to below as searchstr
#
# - Exits with return value 1 error and print statements if any of the
# parameters above were not specified
#
# - Exits with return value 1 error and print statements if filesdir does not
# represent a directory on the filesystem
#
# - Prints a message "The number of files are X and the number of matching
# lines are Y" where X is the number of files in the directory and all
# subdirectories and Y is the number of matching lines found in respective
# files.

# Check command line arguments.
if [ $# != 2 ]; then
	echo "Usage: $0 <filesdir> <searchstr>"
	exit 1
fi

filesdir=$1
searchstr=$2

# Make sure filesdir exists.
if [ ! -d $filesdir ]; then
	echo "Directory '$filesdir' does not exist."
	exit 1
fi

# Look for files and matches.
numfiles=$(find "$filesdir" -type f | wc -l)
nummatches=$(grep -R "$searchstr" "$filesdir" | wc -l)
echo "The number of files are $numfiles and the number of matching lines are $nummatches"

