#!/usr/bin/osascript
-- Resize/center a window.
-- argv: bundleId, widthSpec, heightSpec, [pid]
-- Specs: "70", "70%", or "480px" (bare number = percent).
--
-- Picks the best window (prefers AXStandardWindow / largest), because some apps
-- (e.g. Things) expose tiny AXUnknown windows that steal "front window".

on run argv
	if (count of argv) < 3 then error "bundle id, width, height required"
	
	set targetBundle to item 1 of argv
	set widthSpec to item 2 of argv as text
	set heightSpec to item 3 of argv as text
	set targetPid to missing value
	if (count of argv) ≥ 4 and (item 4 of argv) is not "" then
		set targetPid to (item 4 of argv) as number
	end if
	
	tell application "Finder"
		set desktopBounds to bounds of window of desktop
	end tell
	set screenX to item 1 of desktopBounds
	set screenY to item 2 of desktopBounds
	set screenW to (item 3 of desktopBounds) - screenX
	set screenH to (item 4 of desktopBounds) - screenY
	
	-- Keep clear of the menu bar (Finder desktop bounds include it).
	set menuBar to 25
	set screenY to screenY + menuBar
	set screenH to screenH - menuBar
	
	set newW to my resolveSize(widthSpec, screenW)
	set newH to my resolveSize(heightSpec, screenH)
	set newX to screenX + (screenW - newW) / 2
	set newY to screenY + (screenH - newH) / 2
	
	tell application "System Events"
		if targetPid is not missing value then
			set targetProc to first application process whose unix id is targetPid
		else
			set targetProc to first application process whose frontmost is true
			if (bundle identifier of targetProc) is not targetBundle then
				set targetProc to first application process whose bundle identifier is targetBundle
			end if
		end if
		
		set win to my bestWindow(targetProc)
		if win is missing value then error "no windows"
		
		set {winX, winY} to position of win
		set {winW, winH} to size of win
		
		if (my absVal(winX - newX) ≤ 8) and (my absVal(winY - newY) ≤ 8) and ¬
			(my absVal(winW - newW) ≤ 8) and (my absVal(winH - newH) ≤ 8) then return
		
		set size of win to {newW, newH}
		set position of win to {newX, newY}
		set size of win to {newW, newH}
	end tell
end run

-- Prefer a real standard window; fall back to the largest usable one.
on bestWindow(targetProc)
	tell application "System Events"
		tell targetProc
			if (count of windows) is 0 then return missing value
			
			set standardWin to missing value
			set largestWin to missing value
			set bestArea to 0
			
			repeat with w in windows
				set s to size of w
				set area to (item 1 of s) * (item 2 of s)
				
				set isStandard to false
				try
					if (subrole of w) is "AXStandardWindow" then set isStandard to true
				end try
				
				if isStandard then
					if standardWin is missing value then
						set standardWin to w
					else
						-- Keep the largest standard window if several exist.
						set ss to size of standardWin
						set standardArea to (item 1 of ss) * (item 2 of ss)
						if area > standardArea then set standardWin to w
					end if
				end if
				
				-- Ignore tiny ghost windows (Things exposes 40x40 AXUnknown ones).
				if area ≥ 10000 and area > bestArea then
					set bestArea to area
					set largestWin to w
				end if
			end repeat
			
			if standardWin is not missing value then return standardWin
			if largestWin is not missing value then return largestWin
			return front window
		end tell
	end tell
end bestWindow

on resolveSize(spec, screenSize)
	set s to my trim(spec as text)
	set u to my lowerCase(s)
	
	if u ends with "px" then
		set numText to text 1 thru -3 of s
		return (my trim(numText) as number)
	end if
	
	if u ends with "%" then
		set numText to text 1 thru -2 of s
		return screenSize * ((my trim(numText) as number) / 100)
	end if
	
	-- Bare number → percent (backwards compatible)
	return screenSize * ((s as number) / 100)
end resolveSize

on trim(s)
	set s to s as text
	repeat while s starts with space or s starts with tab
		if length of s is 1 then return ""
		set s to text 2 thru -1 of s
	end repeat
	repeat while s ends with space or s ends with tab
		if length of s is 1 then return ""
		set s to text 1 thru -2 of s
	end repeat
	return s
end trim

on lowerCase(s)
	set s to s as text
	set upper to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	set lower to "abcdefghijklmnopqrstuvwxyz"
	set out to ""
	repeat with ch in characters of s
		set c to ch as text
		set p to offset of c in upper
		if p > 0 then
			set out to out & text p thru p of lower
		else
			set out to out & c
		end if
	end repeat
	return out
end lowerCase

on absVal(n)
	if n < 0 then return -n
	return n
end absVal
