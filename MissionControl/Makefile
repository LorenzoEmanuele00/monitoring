# Build + install pipeline for MissionControl.app.
#
# Why this exists: running via Xcode's Cmd-R builds into a hash-suffixed DerivedData path
# that changes every time the project is regenerated (or a worker builds in its own
# worktree). Every one of those paths ends up registered with LaunchServices/pluginkit, and
# once there are several "MissionControl.app" candidates macOS stops being able to tell
# which one is canonical — the widget silently drops out of the widget gallery and the
# resident menu-bar app can end up stuck on a stale, orphaned build. `make install` always
# builds to the same pinned DerivedData path, unregisters every OTHER MissionControl.app /
# MissionControlWidgets.appex path LaunchServices knows about, and installs the one true
# copy to /Applications.

PROJECT        := MissionControl.xcodeproj
SCHEME         := MissionControl
CONFIGURATION  := Debug
DERIVED_DATA   := $(CURDIR)/DerivedData
APP_NAME       := MissionControl.app
BUILT_APP      := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/$(APP_NAME)
DEST           := /Applications/$(APP_NAME)
WIDGET_BUNDLE_ID := com.lorenzoemanuele.missioncontrol.widgets
LSREGISTER     := /System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister

.DEFAULT_GOAL := install
.PHONY: build install clean-registrations uninstall

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) \
		-derivedDataPath $(DERIVED_DATA) -destination 'platform=macOS' -allowProvisioningUpdates build

install: build clean-registrations
	@echo "Installing $(APP_NAME) to /Applications..."
	@pkill -f "$(APP_NAME)/Contents/MacOS/MissionControl" 2>/dev/null || true
	@rm -rf "$(DEST)"
	@ditto "$(BUILT_APP)" "$(DEST)"
	@"$(LSREGISTER)" -f "$(DEST)"
	@pluginkit -e use -i $(WIDGET_BUNDLE_ID) 2>/dev/null || true
	@open "$(DEST)"
	@echo "Installed and launched: $(DEST)"

# Unregisters every MissionControl.app / MissionControlWidgets.appex path LaunchServices
# knows about other than the current /Applications install — dead DerivedData hashes,
# worker worktree/scratchpad builds, etc. Safe to run on its own whenever the widget picker
# looks wrong, without doing a full rebuild.
clean-registrations:
	@"$(LSREGISTER)" -dump 2>/dev/null \
		| sed -nE 's/^path:[[:space:]]+(.*) \(0x[0-9a-f]+\)$$/\1/p' \
		| grep -E 'MissionControl(Widgets)?\.(app|appex)$$' \
		| sort -u \
		| grep -vF -- "$(DEST)" \
		| while read -r p; do \
			echo "  unregistering stale: $$p"; \
			"$(LSREGISTER)" -u "$$p" 2>/dev/null || true; \
		done

uninstall:
	@pkill -f "$(APP_NAME)/Contents/MacOS/MissionControl" 2>/dev/null || true
	@"$(LSREGISTER)" -u "$(DEST)" 2>/dev/null || true
	@rm -rf "$(DEST)"
	@echo "Removed $(DEST)"
