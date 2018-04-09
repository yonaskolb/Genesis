TOOL_NAME = Genesis
export EXECUTABLE_NAME = genesis
VERSION = 0.1.0

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(EXECUTABLE_NAME)
SHARE_PATH = $(PREFIX)/share/$(EXECUTABLE_NAME)
CURRENT_PATH = $(PWD)
FORMULA = Formula/$(EXECUTABLE_NAME).rb
REPO = https://github.com/yonaskolb/$(EXECUTABLE_NAME)
RELEASE_TAR = $(REPO)/archive/$(VERSION).tar.gz
#SHA = $(shell curl -L -s $(RELEASE_TAR) | shasum -a 256 | sed 's/ .*//')

.PHONY: install build uninstall format_code update_brew release

install: build
	mkdir -p $(PREFIX)/bin
	cp -f .build/release/$(EXECUTABLE_NAME) $(INSTALL_PATH)

build:
	swift build --disable-sandbox -c release -Xswiftc -static-stdlib

uninstall:
	rm -f $(INSTALL_PATH)
	rm -rf $(SHARE_PATH)

format_code:
	swiftformat Tests --wraparguments beforefirst --stripunusedargs closure-only --header strip --disable blankLinesAtStartOfScope
	swiftformat Sources --wraparguments beforefirst --stripunusedargs closure-only --header strip --disable blankLinesAtStartOfScope
	git add .
	git commit -m "Format code with `swiftformat --version`"

update_brew:
	sed -i '' 's|\(url ".*/archive/\)\(.*\)\(.tar\)|\1$(VERSION)\3|' $(FORMULA)
	sed -i '' 's|\(sha256 "\)\(.*\)\("\)|\1$(SHA)\3|' $(FORMULA)

	git add .
	git commit -m "Update brew to $(VERSION)"

release: format_code
	sed -i '' 's|\(let version = "\)\(.*\)\("\)|\1$(VERSION)\3|' Sources/XcodeGen/main.swift

	git add .
	git commit -m "Update to $(VERSION)"
	git tag $(VERSION)
