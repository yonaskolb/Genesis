TOOL_NAME = Genesis
export EXECUTABLE_NAME = genesis
VERSION = 0.6.0

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(EXECUTABLE_NAME)
FORMULA = Formula/$(EXECUTABLE_NAME).rb
REPO = https://github.com/yonaskolb/$(EXECUTABLE_NAME)
RELEASE_TAR = $(REPO)/archive/$(VERSION).tar.gz
SWIFT_BUILD_FLAGS = --disable-sandbox -c release --arch arm64 --arch x86_64
EXECUTABLE_PATH = $(shell swift build $(SWIFT_BUILD_FLAGS) --show-bin-path)/$(EXECUTABLE_NAME)

.PHONY: install build uninstall format_code release

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(EXECUTABLE_PATH) $(INSTALL_PATH)

build:
	swift build $(SWIFT_BUILD_FLAGS)

uninstall:
	rm -f $(INSTALL_PATH)
	rm -rf $(SHARE_PATH)

format_code:
	swiftformat Tests --wraparguments beforefirst --stripunusedargs closure-only --header strip --disable blankLinesAtStartOfScope
	swiftformat Sources --wraparguments beforefirst --stripunusedargs closure-only --header strip --disable blankLinesAtStartOfScope

commit_format_code: format_code
	git add .
	git commit -m "Format code with `swiftformat --version`"

release: format_code
	sed -i '' 's|\(let version = "\)\(.*\)\("\)|\1$(VERSION)\3|' Sources/GenesisCLI/GenesisCLI.swift

	git add .
	git commit -m "Update to $(VERSION)"
	git tag $(VERSION)
