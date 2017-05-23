/*
 * Program ensures durability of files on disk
 */

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

#include "logger.h"
#include "sync.h"

int current_logger_level = LOGGER_ERROR;

/*
 * Function: help
 *
 * Print help message for this tool.
 */
void help() {
	printf("Usage: syncit [-d] [-h] file\n");
}

/*
 * Function: main
 */
int main(int argc, char * argv[]) {
	int ret;
	int opt = 0;
	char * path = NULL;
	static struct option long_options[] = {
		{"help", no_argument, 0, 'h' },
		{"debug", no_argument, 0, 'd' },
		{0, 0, 0, 0}
	};
	int long_index = 0;

	while ((opt = getopt_long(argc, argv,"hdf:", long_options, &long_index )) != -1) {
		switch (opt) {
			case 'h':
				help();
				exit(EXIT_SUCCESS);
				break;
			case 'd':
				current_logger_level = LOGGER_DEBUG;
				break;
			default:
				help();
				exit(EXIT_FAILURE);
		}
	}

	if (optind < argc) {
		path = argv[argc - 1]; /* Take the last argument as the file */
	}

	return syncToDisk(path);
}
