#include <fcntl.h>
#include <libgen.h>
#include <sys/stat.h>
#include <unistd.h>

#include "logger.h"

/*
 * Function: syncAndClose
 *
 * Syncs a file descriptor to disk and closes it afterwards.
 *
 * fd: File descriptor to be used.
 */
int syncAndClose(int fd) {
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
 * Sync a file and it's parent directory to disk.
 *
 * path: File path.
 */
int syncToDisk(char * path) {
	int r, mode;
	struct stat path_stat;

	/* Sync all if no path was provided */
	if (!path) {
		logger(LOGGER_INFO, "No path provided. Sync all buffered modifications.\n");
		sync();
		return 1;
	}

	r = stat(path, &path_stat);
	if (r != 0)
		logger(LOGGER_ERROR, "Can't stat the file '%s'.\n", path);
	mode = path_stat.st_mode & S_IFMT;

	/* Sync file */
	logger(LOGGER_INFO, "Sync file %s to disk.\n", path);
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
	if (syncAndClose(r) != 0)
		logger(LOGGER_ERROR, "Failed to sync.");

	/* Sync parent directory */
	logger(LOGGER_INFO, "Sync parent directory of file '%s' to disk.\n", path);
	logger(LOGGER_DEBUG, "Parent directory of '%s' is '%s'.\n", path, dirname(path));
	if ((r = open(dirname(path), O_RDONLY | O_DIRECTORY)) == -1)
		logger(LOGGER_ERROR, "Can't open parent directory.");
	if (syncAndClose(r) != 0)
		logger(LOGGER_ERROR, "Failed to sync.");

	return 0;
}
