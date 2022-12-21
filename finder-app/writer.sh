#!/bin/bash
# Write a shell script finder-app/writer.sh as described below
# 
# - Accepts the following arguments: the first argument is a full path to a
# file (including filename) on the filesystem, referred to below as writefile;
# the second argument is a text string which will be written within this file,
# referred to below as writestr
# 
# - Exits with value 1 error and print statements if any of the arguments above
# were not specified
# 
# - Creates a new file with name and path writefile with content writestr,
# overwriting any existing file and creating the path if it doesn’t exist.
# Exits with value 1 and error print statement if the file could not be
# created.

# Check command line arguments.
if [ $# != 2 ]; then
	echo "Usage: $0 <writefile> <writestr>"
	exit 1
fi

writefile=$1
writestr=$2

# Create the target directory if needed.
writedir=$(dirname "$writefile")
if [ ! -d "$writedir" ]; then
	mkdir -p "$writedir"
	if [ $? != 0 ]; then
		print "Error creating directory '$writedir'"
		exit 1
	fi
fi

# Create the file.
echo "$writestr" > "$writefile"
if [ $? != 0 ]; then
	print "Error creating file '$writefile'"
	exit 1
fi

