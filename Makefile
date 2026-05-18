CLAUDE_PLUGIN_VALIDATE ?= claude-plugin-validate

.PHONY: all test test-hooks lint lint-executable lint-json lint-policy shellcheck validate validate-marketplace validate-plugin diff-check release-check clean

all: lint test

test: test-hooks

test-hooks:
	bats tests/ --jobs 4

lint: lint-executable lint-json lint-policy shellcheck
	@echo "All checks passed."

lint-executable:
	@echo "Checking hook scripts are executable..."
	@fail=0; \
	for f in plugin/scripts/*.sh; do \
		test -x "$$f" || { echo "FAIL: $$f not executable"; fail=1; }; \
	done; \
	[ "$$fail" -eq 0 ] || exit 1

lint-json:
	@echo "Checking marketplace.json is valid JSON..."
	@jq empty .claude-plugin/marketplace.json
	@echo "Checking hooks.json is valid JSON..."
	@jq empty plugin/hooks/hooks.json
	@echo "Checking plugin.json is valid JSON..."
	@jq empty plugin/.claude-plugin/plugin.json

lint-policy:
	@echo "Checking plugin does not require MCP for first value..."
	@test ! -f plugin/.mcp.json
	@! jq -e 'has("mcpServers")' plugin/.claude-plugin/plugin.json >/dev/null
	@echo "Checking plugin does not vendor duplicated command surface..."
	@test ! -d plugin/commands || [ -z "$$(find plugin/commands -type f -print -quit)" ]

shellcheck:
	shellcheck -x plugin/scripts/*.sh tests/helpers/setup.bash

validate: validate-marketplace validate-plugin

validate-marketplace:
	$(CLAUDE_PLUGIN_VALIDATE) .

validate-plugin:
	$(CLAUDE_PLUGIN_VALIDATE) plugin

diff-check:
	git diff --check

release-check: lint test validate diff-check

clean:
	@echo "Nothing to clean."
