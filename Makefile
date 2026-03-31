.PHONY: test test-hooks lint

test: test-hooks

test-hooks:
	bats tests/ --jobs 4

lint:
	@echo "Checking hook scripts are executable..."
	@for f in plugin/scripts/*.sh; do \
		test -x "$$f" || (echo "FAIL: $$f not executable" && exit 1); \
	done
	@echo "Checking hooks.json is valid JSON..."
	@jq empty plugin/hooks/hooks.json
	@echo "Checking plugin.json is valid JSON..."
	@jq empty plugin/.claude-plugin/plugin.json
	@echo "All checks passed."
