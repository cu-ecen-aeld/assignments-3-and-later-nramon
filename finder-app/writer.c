/*
Write a C application “writer” which can be used as an alternative to the
“writer.sh” test script created in assignment1 and using File IO as described
in LSP chapter 2.  See the Assignment 1 requirements for the writer.sh test
script and these additional instructions:

One difference from the write.sh instructions in Assignment 1:  You do not need
to make your "writer" utility create directories which do not exist.  You can
assume the directory is created by the caller.

Setup syslog logging for your utility using the LOG_USER facility.

Use the syslog capability to write a message “Writing <string> to <file>” where
<string> is the text string written to file (second argument) and <file> is the
file created by the script.  This should be written with LOG_DEBUG level.

Use the syslog capability to log any unexpected errors with LOG_ERR level.


*/

#include <stdio.h>
#include <string.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
	char *string, *file;
	FILE *fh;

	/* Check command line arguments. */
	if (argc != 3) {
		printf("Usage: %s <file> <string>\n", argv[0]);
		return 1;
	}
	file = argv[1];
	string = argv[2];

	/* Open a connection to Syslog. */
	openlog(NULL, 0, LOG_USER);

	/* Open the file for writing. */
	fh = fopen(file, "w");
	if (fh == NULL) {
		syslog(LOG_ERR, "Error opening file '%s'.", file);
		return 1;
	}
	
	/* Write the given string to the file. */
	if (fprintf(fh, "%s", string) < 0) {
		syslog(LOG_ERR, "Error writing to file '%s'.", file);
		fclose(fh);
		return 1;
	}

	/* Log a message and clean up. */
	syslog(LOG_DEBUG, "Writing %s to %s", string, file);
	fclose(fh);

	return 0;
}
