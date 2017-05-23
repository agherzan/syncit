PROGRAM := syncit
objects := src/main.o src/logger.o src/sync.o

CC := gcc
CFLAGS := -I./include
DEST := /usr/bin

.PHONY: all
all: $(PROGRAM)

$(PROGRAM): $(objects)
	$(CC) -o $@ $^ $(CFLAGS)

.PHONY: install
install: all
	install $(PROGRAM) $(DEST)

.PHONY : clean
clean :
	rm -f $(PROGRAMS) $(objects)
