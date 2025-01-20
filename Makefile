# Use OS-agnostic path separator
ifeq ($(OS),Windows_NT)
    PATH_SEP = \\
    TSC = lua_modules\bin\tsc.bat
    PATHSEP = \\
else
    PATH_SEP = /
    TSC = lua_modules/bin/tsc
    PATHSEP = /
endif

# Directories
TEST_DIR = test
SRC_DIR = src

# Automatically find all test files
TEST_FILES := $(wildcard $(TEST_DIR)$(PATHSEP)*_spec.lua)
TEST_TARGETS := $(notdir $(basename $(TEST_FILES)))

# Main file
MAIN_FILE = $(SRC_DIR)$(PATHSEP)main.lua

# Debug info (uncomment to debug)
# $(info TEST_FILES = $(TEST_FILES))
# $(info TEST_TARGETS = $(TEST_TARGETS))

# General TSC command for any file
tsc:
	$(TSC) -f $(file)

# Run all tests
test: $(TEST_TARGETS)
	@echo "All tests completed"

# Pattern rule for test files
%_spec: $(TEST_DIR)$(PATHSEP)%_spec.lua
	@echo "Running test: $<"
	@if [ ! -f "$<" ]; then \
		echo "Error: Test file $< not found"; \
		exit 1; \
	fi
	$(TSC) -f $<

main:
	@lua $(MAIN_FILE)

# Clean target
clean:
	@echo "Cleaning..."
	# Add commands to clean temporary files if needed

# Mark targets as phony
.PHONY: tsc test $(TEST_TARGETS) main clean

# Help target
help:
	@echo "Available targets:"
	@echo "  test          - Run all tests"
	@echo "  <name>_spec   - Run specific test (e.g., make example_spec)"
	@echo "  main          - Run main program"
	@echo "  clean         - Clean temporary files"
	@echo "  help          - Show this help message"

.PHONY: help