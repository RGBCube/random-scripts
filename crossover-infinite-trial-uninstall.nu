#!usr/bin/env nu

print --stderr $"(ansi yellow)moving CrossOver.origin to CrossOver(ansi reset)"
mv /Applications/CrossOver.app/Contents/MacOS/CrossOver.origin /Applications/CrossOver.app/Contents/MacOS/CrossOver

print --stderr $"(ansi green)all done!(ansi reset)"
