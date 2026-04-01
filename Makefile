.PHONY: all test test-hooks lint clean

all: lint test

test: test-hooks

test-hooks:
	bats tests/ --jobs 4

lint:
	@echo "Checking hook scripts are executable..."
	@fail=0; \
	for f in plugin/scripts/*.sh; do \
		test -x "$$f" || { echo "FAIL: $$f not executable"; fail=1; }; \
	done; \
	[ "$$fail" -eq 0 ] || exit 1
	@echo "Checking hooks.json is valid JSON..."
	@jq empty plugin/hooks/hooks.json
	@echo "Checking plugin.json is valid JSON..."
	@jq empty plugin/.claude-plugin/plugin.json
	@echo "All checks passed."

clean:
	@echo "Nothing to clean."
