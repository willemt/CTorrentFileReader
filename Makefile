CONTRIB_DIR = ..
BENCODE_DIR = $(CONTRIB_DIR)/CHeaplessBencodeReader

GCOV_OUTPUT = *.gcda *.gcno *.gcov 
GCOV_CCFLAGS = -fprofile-arcs -ftest-coverage
SHELL  = /bin/bash
CC     = gcc
CCFLAGS = -g -O2 -Wall -Werror -W -fno-omit-frame-pointer -fno-common -fsigned-char $(GCOV_CCFLAGS) -I$(BENCODE_DIR)

ifeq ($(OS),Windows_NT)
    CCFLAGS += -D WIN32
    ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
        CCFLAGS += -D AMD64
    endif
    ifeq ($(PROCESSOR_ARCHITECTURE),x86)
        CCFLAGS += -D IA32
    endif
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        CCFLAGS += -D LINUX
    endif
    ifeq ($(UNAME_S),Darwin)
        CCFLAGS += -D OSX
    endif
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
        CCFLAGS += -D AMD64
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
        CCFLAGS += -D IA32
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
        CCFLAGS += -D ARM
    endif
endif


all: tests

bencode:
	mkdir -p $(BENCODE_DIR)/.git
	git --git-dir=$(BENCODE_DIR)/.git init 
	pushd $(BENCODE_DIR); git pull git@github.com:willemt/CHeaplessBencodeReader.git; popd

download-contrib: cheap

main.c:
	if test -d $(BENCODE_DIR); \
	then echo have contribs; \
	else make download-contrib; \
	fi
	sh make-tests.sh > main.c

tests: main.c torrentfile_reader.o test_torrentfile_reader.c CuTest.c main.c $(BENCODE_DIR)/bencode.c 
	$(CC) $(CCFLAGS) -o $@ $^
	gcov torrentfile_reader.c
	./tests

torrentfile_reader.o: torrentfile_reader.c
	$(CC) $(CCFLAGS) -c -o $@ $^

clean:
	rm -f main.c *.o tests $(GCOV_OUTPUT)
