#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <signal.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <syslog.h>
#include <arpa/inet.h>
#include <unistd.h>

#define BUFF_SIZE    512                       /* Buffer for socket reads. */
#define CONN_BACKLOG 10                        /* Backlog size for listen. */
#define OUT_FILE     "/var/tmp/aesdsocketdata" /* Output file. */
#define SRV_PORT     9000                      /* Port where the server will listen. */

/* Server socker. Must be accessible for the signal handler. */
int srv_fd = 0;

/******************************************************************************/
/* Signal handler.                                                            */
/******************************************************************************/
void quit(int sig) {
	close(srv_fd);
}

/******************************************************************************/
/* Main.                                                                      */
/******************************************************************************/
int main(int argc, char *argv[]) {
	int cli_fd, cli_addr_len;
	int enable = 1, num_read = 0;
	char cli_ip[INET_ADDRSTRLEN], buffer[BUFF_SIZE];
	struct sockaddr_in srv_addr, cli_addr;
	FILE *fh;
	
	/* Open a connection to Syslog. */
	openlog(NULL, 0, LOG_USER);

	/* Open the output file. */
	fh = fopen(OUT_FILE, "a+");
	if (fh == NULL) {
		perror("fopen");
		return -1;
	}

	/* Initialize the socket. */
	srv_fd = socket(AF_INET, SOCK_STREAM, 0);
	if (srv_fd == -1) {
		perror("socket");
		fclose(fh);
		return -1;
	}

	if (setsockopt(srv_fd, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) == -1) {
		perror("socket");
		return -1;
	}

	/* Assign a name to the socket. */
	memset(&srv_addr, 0, sizeof(srv_addr));
	srv_addr.sin_family = AF_INET;
	srv_addr.sin_addr.s_addr = INADDR_ANY;
	srv_addr.sin_port = htons(SRV_PORT);
	if (bind(srv_fd, (struct sockaddr *) &srv_addr, sizeof(srv_addr)) == -1) {
 		perror("bind");
		fclose(fh);
		return -1;
	}

	/* Listen for new connections. */
	if (listen(srv_fd, CONN_BACKLOG) == -1) {
 		perror("listen");
		fclose(fh);
		return -1;
	}

	/* Daemonize. */
	if (argc == 2 && strcmp("-d", argv[1]) == 0) {
		daemon(0, 0);
	}

	/* Handle signals. */
	signal(SIGINT, quit);
	signal(SIGTERM, quit);

	/* Accept connections. */
	cli_addr_len = sizeof(cli_addr);
	for (;;) {
		cli_fd = accept(srv_fd, (struct sockaddr *) &cli_addr, &cli_addr_len);
		if (cli_fd == -1) {

			/* Exit. */
			if (errno == 9) {
				syslog(LOG_DEBUG, "Caught signal, exiting");
				fclose(fh);
				unlink(OUT_FILE);
				return 0;
			}

 			perror("accept");
			continue;
		}

		/* Serve the client. */
		inet_ntop(AF_INET, &(cli_addr.sin_addr), cli_ip, INET_ADDRSTRLEN);
		syslog(LOG_DEBUG, "Accepted connection from %s", cli_ip);
	
		for (;;) {
			num_read = read(cli_fd, buffer, BUFF_SIZE - 1); /* Leave room in the buffer for the trailing '\0'. */
			if (num_read == -1) {
 				perror("read");
				break;
			}

			/* Should not happen. */
			if (num_read == 0) {
				break;
			}

			/* Write data to the output file. */
			buffer[num_read] = '\0';
			fprintf(fh, "%s", buffer);

			/* No more data. */
			if (buffer[num_read - 1] == '\n') {

				/* Move to the start of the output file. */
				rewind(fh);

				/* Send data back to the client. */
				for (;;) {
					num_read = fread(buffer, 1, BUFF_SIZE, fh);
					if (num_read == -1) {
						perror("fread");
						break;
					}

					/* No more data. */
					if (num_read == 0) {
						break;
					}

					if (write(cli_fd, buffer, num_read) == -1) {
 						perror("write");
						break;
					}
				}

				break;
			}
		}
			
		syslog(LOG_DEBUG, "Closed connection from %s", cli_ip);
		close(cli_fd);
		unlink(OUT_FILE);
	}

	return 0;
}
