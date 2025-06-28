CC = gcc
CFLAGS = -Wall -Wextra -Werror -fPIE
TEST_FLAGS = -lcheck -lm -lpthread

SRC_DIR = src
BUILD_DIR = build

SRCS = $(wildcard $(SRC_DIR)/*.c $(SRC_DIR)/*/*.c)
OBJS = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS))

.PHONY: all test clean

all: gacp-app

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c $< -o $@

gacp-app: $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

test:
	$(CC) $(CFLAGS) tests/unit/*.c $(SRCS) $(TEST_FLAGS) -o unit-tester
	./unit-tester

clean:
	rm -rf $(BUILD_DIR) gacp-app unit-tester
