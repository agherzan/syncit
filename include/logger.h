#define LOGGER_ERROR 1
#define LOGGER_WARN 2
#define LOGGER_INFO 3
#define LOGGER_DEBUG 4

int logger(int logger_level, const char * format, ...);
