#
# Copyright 2017 Andrei Gherzan
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Version
SYNCIT_MAJOR = 0
SYNCIT_MINOR = 0
SYNCIT_PATCH = 1

SRC_DIR := $(shell pwd)
BUILD_DIR := $(shell pwd)
PROGRAM := $(BUILD_DIR)/syncit
SOURCES = $(wildcard $(SRC_DIR)/src/*.c)
OBJECTS = $(patsubst $(SRC_DIR)/src/%.c,$(BUILD_DIR)/obj/%.o,$(SOURCES))
CC := gcc
CFLAGS += -I$(SRC_DIR)/include
CFLAGS += -I$(BUILD_DIR)/include
INSTALL_DEST := /usr/bin


.PHONY: all
all: dir $(PROGRAM)

dir:
	mkdir -p $(BUILD_DIR)/include
	mkdir -p $(BUILD_DIR)/obj

version.h:
	mkdir -p $(BUILD_DIR)/include
	echo "#define SYNCIT_MAJOR $(SYNCIT_MAJOR)" > $(BUILD_DIR)/include/$@
	echo "#define SYNCIT_MINOR $(SYNCIT_MINOR)" >> $(BUILD_DIR)/include/$@
	echo "#define SYNCIT_PATCH $(SYNCIT_PATCH)" >> $(BUILD_DIR)/include/$@
	echo -n '#define SYNCIT_GITHASH "' >> $(BUILD_DIR)/include/$@
	git rev-parse --short HEAD | tr -d "\n" >> $(BUILD_DIR)/include/$@
	echo '"' >> $(BUILD_DIR)/include/$@

$(BUILD_DIR)/obj/main.o: version.h $(SRC_DIR)/src/main.c
	$(CC) -c $(CFLAGS) $(SRC_DIR)/src/main.c -o $(BUILD_DIR)/obj/main.o

$(BUILD_DIR)/obj/%.o: $(SRC_DIR)/src/%.c
	$(CC) -c $(CFLAGS) $< -o $@

$(PROGRAM): $(OBJECTS)
	$(CC) -o $@ $^ $(CFLAGS)

.PHONY: install
install: all
	mkdir -p $(INSTALL_DEST)
	install $(PROGRAM) $(INSTALL_DEST)

.PHONY : clean
clean :
	rm -f $(PROGRAM) $(OBJECTS) $(BUILD_DIR)/include/version.h
