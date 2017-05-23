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

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "logger.h"

extern int current_logger_level;

/*
 * Function: logger
 *
 * Logs to stdout with messsage tag.
 *
 * logger_level:	Used when printing messsages as log tag.
 *			If level is LOGGER_ERROR, exit program.
 */
int logger(int logger_level, const char *format, ...) {
	va_list args;

	if (current_logger_level < logger_level)
		return 0;

	va_start(args, format);
	switch (logger_level) {
		case LOGGER_ERROR:
			printf("[ERROR] ");
			break;
		case LOGGER_WARN:
			printf("[WARN] ");
			break;
		case LOGGER_INFO:
			printf("[INFO ] ");
			break;
		case LOGGER_DEBUG:
			printf("[DEBUG] ");
			break;
		default:
			/* Should never reach this */
			printf("Unknown log level %d.\n", logger_level);
			exit(EXIT_FAILURE);
	}
	va_start(args, format);
	vprintf(format, args);
	va_end(args);
	if (logger_level == LOGGER_ERROR)
		exit(EXIT_FAILURE);
	return 0;
}
