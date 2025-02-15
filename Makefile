.PHONY: init
init:
	dart version

.PHONY: test
test:
	dart run coverage:test_with_coverage
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html

.PHONY: build
build:
	dart run build_runner build --delete-conflicting-outputs
