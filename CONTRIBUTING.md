CC = gcc
CFLAGS = -Wall -Wextra -Werror -fPIE -D_FORTIFY_SOURCE=2
TEST_FLAGS = -lcheck -lm -lpthread

SRC = $(wildcard src/**/*.c src/*.c)
OBJ = $(SRC:.c=.o)

.PHONY: all test-unit fuzz

all: gacp-bin

gacp-bin: $(OBJ)
	$(CC) $(CFLAGS) $^ -o $@

test-unit:
	$(CC) $(CFLAGS) tests/unit/*.c $(SRC) $(TEST_FLAGS) -o unit-tester
	./unit-tester

fuzz:
	clang -fsanitize=fuzzer tests/fuzz/fuzz_parser.c src/core/parser.c -o fuzzer
	./fuzzer -max_total_time=300
