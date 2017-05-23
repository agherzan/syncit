/*
 * Copyright 2017 Andrei Gherzan
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
	printf("Usage: syncit [-d|--debug] [-h|--help] file\n");
}

/*
 * Function: main
 */
int main(int argc, char * argv[]) {
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
