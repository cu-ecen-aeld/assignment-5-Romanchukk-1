# Makefile template

.PHONY: all clean help

# Variables
CC = gcc
CFLAGS = -Wall -Wextra -O2
TARGET = pid_test
SOURCES = $(wildcard *.c)
OBJECTS = $(SOURCES:.c=.o)

# Targets
all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

help:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  all   - Build the program (default)"
	@echo "  clean - Remove built files"
	@echo "  help  - Show this message"