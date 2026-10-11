TAP_DIR ?= $(abspath ../homebrew-tap)
MARKETING_VERSION := $(shell sed -nE 's/.*MARKETING_VERSION = ([^;]+);.*/\1/p' Amethyst.xcodeproj/project.pbxproj | head -1)
BUILD_NUMBER := $(shell git rev-list --count HEAD)

.PHONY: help build archive test clean tap

help:
	@echo "Available targets:"
	@echo "  make build    - Build Debug target"
	@echo "  make archive  - Build Release archive and package zip"
	@echo "  make test     - Run tests"
	@echo "  make tap      - Update Homebrew Tap (Casks/amethyst.rb) with current version & checksum"
	@echo "  make clean    - Clean build artifacts"

build:
	xcodebuild -workspace Amethyst.xcworkspace -scheme Amethyst -configuration Debug -destination 'platform=macOS' build

archive:
	mkdir -p build/artifacts
	xcodebuild -quiet archive \
		-workspace Amethyst.xcworkspace -scheme Amethyst -configuration Release \
		-destination 'platform=macOS' -derivedDataPath build/dd -archivePath build/Amethyst.xcarchive \
		MARKETING_VERSION="$(MARKETING_VERSION)" CURRENT_PROJECT_VERSION="$(BUILD_NUMBER)" \
		CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" CODE_SIGN_IDENTITY="-"
	ditto -c -k --keepParent build/Amethyst.xcarchive/Products/Applications/Amethyst.app "build/artifacts/Amethyst-v$(MARKETING_VERSION)-b$(BUILD_NUMBER).zip"
	ditto -c -k build/Amethyst.xcarchive/dSYMs "build/artifacts/Amethyst-v$(MARKETING_VERSION)-b$(BUILD_NUMBER).dSYM.zip"

test:
	xcodebuild -quiet test -workspace Amethyst.xcworkspace -scheme Amethyst -destination 'platform=macOS' -derivedDataPath build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

clean:
	rm -rf build

tap:
	@echo "Updating Homebrew tap at $(TAP_DIR)..."
	@if [ ! -d "$(TAP_DIR)" ]; then \
		echo "Error: Tap directory $(TAP_DIR) not found. Set TAP_DIR=/path/to/homebrew-tap"; \
		exit 1; \
	fi
	@mkdir -p $(TAP_DIR)/Casks
	@if [ -f "build/artifacts/Amethyst-v$(MARKETING_VERSION)-b$(BUILD_NUMBER).zip" ]; then \
		SHA=$$(shasum -a 256 "build/artifacts/Amethyst-v$(MARKETING_VERSION)-b$(BUILD_NUMBER).zip" | awk '{print $$1}'); \
	else \
		echo "Local artifact not found, fetching release asset SHA from GitHub..."; \
		SHA=$$(curl -sL "https://github.com/mgabs/Amethyst/releases/download/v$(MARKETING_VERSION)/Amethyst-v$(MARKETING_VERSION)-b$(BUILD_NUMBER).zip" | shasum -a 256 | awk '{print $$1}'); \
	fi; \
	echo "Version: $(MARKETING_VERSION),$(BUILD_NUMBER)"; \
	echo "SHA256:  $$SHA"; \
	printf '%s\n' \
		'cask "amethyst" do' \
		'  version "$(MARKETING_VERSION),$(BUILD_NUMBER)"' \
		'  sha256 "'$$SHA'"' \
		'' \
		'  url "https://github.com/mgabs/Amethyst/releases/download/v#{version.csv.first}/Amethyst-v#{version.csv.first}-b#{version.csv.second}.zip"' \
		'  name "Amethyst"' \
		'  desc "Automatic tiling window manager similar to xmonad (mgabs fork)"' \
		'  homepage "https://github.com/mgabs/Amethyst"' \
		'' \
		'  livecheck do' \
		'    url "https://raw.githubusercontent.com/mgabs/Amethyst/master/build/appcast.xml"' \
		'    strategy :sparkle' \
		'  end' \
		'' \
		'  auto_updates true' \
		'  depends_on macos: ">= :monterey"' \
		'' \
		'  app "Amethyst.app"' \
		'' \
		'  zap trash: [' \
		'    "~/Library/Application Support/Amethyst",' \
		'    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.amethyst.amethyst.sfl*",' \
		'    "~/Library/Caches/com.amethyst.Amethyst",' \
		'    "~/Library/Cookies/com.amethyst.Amethyst.binarycookies",' \
		'    "~/Library/HTTPStorages/com.amethyst.Amethyst",' \
		'    "~/Library/Preferences/com.amethyst.Amethyst.plist",' \
		'  ]' \
		'' \
		'  caveats <<~EOS' \
		'    If macOS blocks launch with a malware warning or error -128, run:' \
		'      xattr -dr com.apple.quarantine /Applications/Amethyst.app' \
		'  EOS' \
		'end' > "$(TAP_DIR)/Casks/amethyst.rb"
	@echo "Updated $(TAP_DIR)/Casks/amethyst.rb successfully."
