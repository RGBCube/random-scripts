#!/usr/bin/env nu

if ("/Applications/CrossOver.app/Contents/MacOS/CrossOver.origin" | path exists) {
  print --stderr $"(ansi red)already installed(ansi reset)"
  exit 1
}

print --stderr $"(ansi yellow)moving (ansi green)CrossOver(ansi yellow) binary to (ansi red)CrossOver.origin(ansi reset)"
mv /Applications/CrossOver.app/Contents/MacOS/CrossOver /Applications/CrossOver.app/Contents/MacOS/CrossOver.origin

print --stderr $"(ansi green)writing wrapper script to CrossOver(ansi reset)"
r##'#!/bin/sh

/usr/bin/pkill CrossOver

DATETIME=$(/bin/date -u -v -3H '+%Y-%m-%dT%TZ')

/usr/bin/plutil -replace FirstRunDate -date "$DATETIME" ~/Library/Preferences/com.codeweavers.CrossOver.plist
/usr/bin/plutil -replace SULastCheckTime -date "$DATETIME" ~/Library/Preferences/com.codeweavers.CrossOver.plist

for file in ~/Library/Application\ Support/CrossOver/Bottles/*/.{eval,update-timestamp}; do
  /bin/rm -rf "$file"
done

/Applications/CrossOver.app/Contents/MacOS/CrossOver.origin > /tmp/co_log.log
'## | save /Applications/CrossOver.app/Contents/MacOS/CrossOver

print --stderr $"(ansi cyan)chmod +x'ing CrossOver(ansi reset)"
chmod +x /Applications/CrossOver.app/Contents/MacOS/CrossOver

print --stderr $"(ansi green)all done!(ansi reset)"
