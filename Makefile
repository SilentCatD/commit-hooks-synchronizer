.PHONY: init
init:
	fvm dart version

.PHONY: test
test:
	fvm dart run coverage:test_with_coverage
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html

.PHONY: build
build:
	fvm dart run build_runner build --delete-conflicting-outputs
