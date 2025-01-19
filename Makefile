# Use forward slashes for paths (works on both Windows and Unix)
TSC = lua_modules\bin\tsc.bat

# List all test files
TEST_FILES = test\example1_spec.lua test\example2_spec.lua

# General TSC command for any file
tsc:
	$(TSC) -f $(file)

# Run all tests
test: test_1
	@echo "All tests completed"

test_1:
	$(TSC) -f test/example_spec.lua

# Mark these targets as phony (not actual files)
.PHONY: tsc test test_1 test_2
