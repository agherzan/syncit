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

#define _GNU_SOURCE

#include <fcntl.h>
#include <libgen.h>
#include <sys/stat.h>
#include <unistd.h>

#include "logger.h"

/*
 * Function: syncFsAndClose
 *
 * Syncs the filesystem a file resides on and closes the file descriptor afterwards.
 *
 * fd: File descriptor to be used.
 */
int syncFsAndClose(int fd) {
	if (syncfs(fd) != 0) {
		close(fd);
		return 1;
	}
	close(fd);
	return 0;
}

/*
 * Function: syncFileAndClose
 *
 * Syncs a file descriptor to disk and closes it afterwards.
 *
 * fd: File descriptor to be used.
 */
int syncFileAndClose(int fd) {
	if (fsync(fd) != 0) {
		close(fd);
		return 1;
	}
	close(fd);
	return 0;
}

/*
 * Function: syncToDisk
 *
 * Sync to disk a file, directory, filesystem or everything.
 *
 * path: File path.
 */
int syncToDisk(char * path, int entireFilesystem) {
	int r, mode;
	struct stat path_stat;

	/* Sync all if no path was provided */
	if (!path) {
		logger(LOGGER_INFO, "No path provided. Sync all buffered modifications.\n");
		sync();
		return 0;
	}

	r = stat(path, &path_stat);
	if (r != 0)
		logger(LOGGER_ERROR, "Can't stat the file '%s'.\n", path);
	mode = path_stat.st_mode & S_IFMT;

	switch(mode) {
		case S_IFREG:
			if ((r = open(path, O_RDONLY)) == -1)
				logger(LOGGER_ERROR, "Can't open regular file.");
			break;
		case S_IFDIR:
			if ((r = open(path, O_RDONLY | O_DIRECTORY)) == -1)
				logger(LOGGER_ERROR, "Can't open directory file.");
			break;
		default:
			logger(LOGGER_ERROR, "Unsupported file type.");
	}

	if (entireFilesystem) {
		/* Sync file-system */
		logger(LOGGER_INFO, "Sync file-system determined by '%s'.\n", path);
		if (syncFsAndClose(r) != 0)
			logger(LOGGER_ERROR, "Failed to sync filesystem.\n");
	} else {
		/* Sync file */
		logger(LOGGER_INFO, "Sync file %s to disk.\n", path);
		if (syncFileAndClose(r) != 0)
			logger(LOGGER_ERROR, "Failed to sync file %s.\n", path);
		/* Sync parent directory */
		logger(LOGGER_INFO, "Sync parent directory of file '%s' to disk.\n", path);
		logger(LOGGER_DEBUG, "Parent directory of '%s' is '%s'.\n", path, dirname(path));
		if ((r = open(dirname(path), O_RDONLY | O_DIRECTORY)) == -1)
			logger(LOGGER_ERROR, "Can't open parent directory.");
		if (syncFileAndClose(r) != 0)
			logger(LOGGER_ERROR, "Failed to sync.");
	}

	return 0;
}
