# This is a MidiPipe AppleScript for MacOS that enables Native Instruments Maschine 2 users to use a 
# Novation LaunchPad MK3 Mini to control patterns and loops in Maschine.
#
# When pads on the LaunchPad Mini are pressed, they are passed as MIDI messages through MidiPipe 
# (http://www.subtlesoft.square7.net/MidiPipe.html) to this script that translates those messages 
# into mouse movements and clicks to control Maschine. 
#
# The script uses a command line utility called 'Cliclick' (https://github.com/BlueM/cliclick)to
# control the mouse clicks as well as MacOS's own 'screencapture' to read the status of the patterns
# and other interface elements in Maschine
#
# This script was inspired by a hack posted by D-One on the Native Instruments forum:
# https://www.native-instruments.com/forum/threads/kinda-hacked-machine-ideas-view-for-external-midi-pattern-selection.316506/
#
# Check the GitHub page for more detail and instructions


property firstx : 357 # 'x' where patterns start in Maschine – change to 32 if instrument browser is closed
property firsty : 110 # 'y' where patterns start in Maschine
property dx : 99 # width of pattern slots in Maschine
property dy : 22 # height of pattern slots in Maschine
property paddingx_logic : 5
property paddingy_logic : 65 # assuming the plugin window header is not collapsed
property paddingx_live : 0
property paddingy_live : -10

property active : 3 # LaunchPad intentisty to use for active patterns
property inactive : 1 # LaunchPad intentisty to use for inactive patterns
property user_pad : false # state of 'user' pad on LaunchPad – false until pressed
property keys_pad : false # state of 'keys' pad on LaunchPad – false until pressed

# by default the 'programmer mode' is used on LaunchPad MK3
# change 'legacy' to true for MK2 or if using legacy mode on MK3
property legacy : false

# properties that store whether maschine is used standalone or as VST in Logic / Live
# these are automatically set when 'session' is pressed
property maschine_app : false
property maschine_logic : false
property maschine_live : false

# you may wish to run the patterns in monochrome / grayscale – if so, set this to true
property grayscale : false

# mapping of pads on LaunchPad - starting with top left corner and going row by row
property padNumbers : {{81, 82, 83, 84, 85, 86, 87, 88}, {71, 72, 73, 74, 75, 76, 77, 78}, {61, 62, 63, 64, 65, 66, 67, 68}, {51, 52, 53, 54, 55, 56, 57, 58}, {41, 42, 43, 44, 45, 46, 47, 48}, {31, 32, 33, 34, 35, 36, 37, 38}, {21, 22, 23, 24, 25, 26, 27, 28}, {11, 12, 13, 14, 15, 16, 17, 18}}

# mapping of pads on LaunchPad for legacy mode
property padNumbersLegacy : {{64, 65, 66, 67, 96, 97, 98, 99}, {60, 61, 62, 63, 92, 93, 94, 95}, {56, 57, 58, 59, 88, 89, 90, 91}, {52, 53, 54, 55, 84, 85, 86, 87}, {48, 49, 50, 51, 80, 81, 82, 83}, {44, 45, 46, 47, 76, 77, 78, 79}, {40, 41, 42, 43, 72, 73, 74, 75}, {36, 37, 38, 39, 68, 69, 70, 71}}

# these propeties will store current state of maschine patterns and scenes:

property active_scene : 0
property s2_exists : 0
property selected_pattern : {0, 0}

# used to store current state of LaunchPad colors
property mas_pattern_colors : {{0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}}


# collection of helper handlers/functions:

# handler rgbToHue(r, g, b)
# return hue from rgb colours - from 0-360

on rgbToHue(r, g, b)
	set hue to 0
	
	if (r = g) and (g = b) then return 0
	
	set r to r / 255
	set g to g / 255
	set b to b / 255
	
	# R is highest
	if (r ≥ g and r ≥ b) then
		if (g > b) then
			set min to b
		else
			set min to g
		end if
		set hue to (g - b) / (r - min)
	end if
	
	# G is highest
	if (g > r and g ≥ b) then
		if (r > b) then
			set min to b
		else
			set min to r
		end if
		set hue to 2 + (b - r) / (g - min)
	end if
	
	# B is highest
	if (b > g and b > r) then
		if (r > g) then
			set min to g
		else
			set min to r
		end if
		set hue to 4 + (r - g) / (b - min)
	end if
	
	set hue to (hue * 60 + 22) mod 360
	
	return hue
end rgbToHue


# ------------------------------------------------------------

# handler rgbToIntensity(r, g, b)
# return intensity/brightness on scale 0-4 (as appropriate for LaunchPad colors)

# this is calibrated to translate Maschine's pattern colours
# so all greys will translate to 0 (off)
# dim colors will be 1 (e.g. when a pattern exists, but is currently off)
# and bright colors will be 3 (e.g. when a pattern is selected)

on rgbToIntensity(r, g, b)
	# if it's a shade of grey then return 0
	if (r = g) and (g = b) then
		return 0
	else if (r + g + b > 300) then
		return active # 3
	else
		return inactive # 1
	end if
end rgbToIntensity


# ------------------------------------------------------------

# handler rgbToLPcolor(r, g, b)
# convert rgb to LaunchPad color
# r,g,b from 0-255
# strengh from 0-4, 0 meaning off

on rgbToLPcolor(r, g, b)
	# round hue to scale of 0-13	
	set hue to round (rgbToHue(r, g, b) / 25.714 - 0.5)
	set intensity to rgbToIntensity(r, g, b)
	
	if intensity = 0 then
		return 0
	else
		return hue * 4 + 8 - intensity
	end if
end rgbToLPcolor


# ------------------------------------------------------------

# handler getLPintensity(LPcolor)
# returns intensity from 0 to 4 (0 means off, 4 is brightest)

on getLPintensity(LPcolor)
	if LPcolor > 3 then
		set intensity to 4 - (LPcolor mod 4)
		return intensity
	end if
	
	return 0 # default if not a color
end getLPintensity


# ------------------------------------------------------------

# handler setLPintensity(oldLPcolor, intensity)
# turns existing color to new level of intensity
# returns a LaunchPad pad color

on setLPintensity(oldLPcolor, intensity)
	if oldLPcolor > 3 then
		set baseLPcolor to (oldLPcolor div 4) * 4
		set newLPcolor to baseLPcolor + (4 - intensity)
		return newLPcolor
	end if
	
	return 0 # default if not a color
end setLPintensity


# ------------------------------------------------------------

# handler setLPcolor
# returns MIDI message (list of 3 numbers) to send to Launchpad to turn a pad into a specific color

on setLPcolor(padx, pady, LPcolor)
	set padNumber to item padx of item pady of padNumbers
	set item padx of item pady of mas_pattern_colors to LPcolor
	
	# set active colors to flashing white
	set intensity to getLPintensity(LPcolor)
	if intensity = active then
		return {146, padNumber, 3}
	end if
	
	# otherwise use normal static color
	if grayscale and intensity is inactive then set LPcolor to 103 # for grayscale mode
	return {144, padNumber, LPcolor}
end setLPcolor


# ------------------------------------------------------------

# handler getLPpadXY(midi_note)
# paramter is midi_note as single number – i.e. byte two of the midi note on message
# returns x and y coordinates of the pad corresponding the the given midi note

on getLPpadXY(midi_note)
	repeat with iy from 1 to 8
		repeat with ix from 1 to 8
			if item ix of item iy of padNumbers = midi_note then return {ix, iy}
		end repeat
	end repeat
	return {0, 0}
end getLPpadXY


# ------------------------------------------------------------

# handler fromHex(str)
# returns decimal number converted from hex

on fromHex(str)
	set n to 0
	set i to 1
	repeat with a in reverse of every text item of str
		if a is greater than 9 or a is less than 0 then
			set a to ASCII number of a
			if a is greater than 70 then
				set a to a - 87
			else
				set a to a - 55
			end if
		end if
		set n to n + (a * i)
		set i to (i * 16)
	end repeat
	set oStr to n as text
	return oStr
end fromHex


# ------------------------------------------------------------

# handler findMaschineInstances()
# checks for standalone or plug-in instances and stores state in appropriate properties

on findMaschineInstances()
	tell application "System Events"
		# check if maschine standalone app is running	
		set maschine_app to (name of processes) contains "Maschine 2"
		
		# check if maschine plugin window is open in Logic Pro or Ableton
		set maschine_logic to false
		set maschine_live to false
		if ((name of processes) contains "Logic Pro X") then
			set maschine_logic to ((count of (windows of process "Logic Pro X" whose name contains "maschine")) is not 0)
		end if
		if ((name of processes) contains "Live") then
			set maschine_live to ((count of (windows of process "Live" whose name contains "maschine")) is not 0)
		end if
		
	end tell
end findMaschineInstances


# ------------------------------------------------------------

# handler getMaschinePatternsPosition()
# returns the starting X and Y for maschine patterns relative to screen
# note that the starting point needs to be inside the pattern 
# (the color of the starting pixel will represent the first pattern)

on getMaschinePatternsPosition()
	set {posx, posy} to {-1, -1}
	
	tell application "System Events"
		# set starting position depending on which type of Maschine instance we're using
		if maschine_app then set {posx, posy} to position of first window of process "Maschine 2"
		if maschine_logic then set {posx, posy} to position of (first item of (windows of process "Logic Pro X" whose name contains "maschine"))
		if maschine_live then set {posx, posy} to position of (first item of (windows of process "Live" whose name contains "maschine"))
	end tell
	
	# if no Maschine window was found, return -1	
	if {posx, posy} = {-1, -1} then return {-1, -1}
	
	set x to firstx + posx
	set y to firsty + posy
	
	# account for padding of plugin windows in Logic
	if maschine_logic then
		set x to x + paddingx_logic
		set y to y + paddingy_logic
	end if
	
	
	# account for padding of plugin windows in Live (smaller title bar)	
	if maschine_live then
		set x to x + paddingx_live
		set y to y + paddingy_live
	end if
	
	# if full screen there's no window header, so subtract 25
	if posx is 0 and posy is 0 then set y to y - 25
	return {x, y}
end getMaschinePatternsPosition


# ------------------------------------------------------------

# handler getMaschinePatternColors()
# returns list of all current maschine pattern colors for an 8x8 grid
# as rgb values

on getMaschinePatternColors(gridx, gridy, offsetx, offsety)
	
	set {x, y} to getMaschinePatternsPosition()
	
	set x to x + offsetx * dx
	set y to y + offsety * dy
	
	set sizex to (gridx - 1) * dx + 2 # two extra pixels at the end 
	set sizey to (gridy - 1) * dy + 2 # to check for color if pattern is selected
	
	try
		# take screen capture of Maschine patterns
		set output to do shell script "screencapture -x -R" & x & "," & y & "," & sizex & "," & sizey & " -t bmp $TMPDIR/maschineLP.bmp && xxd -p -l 1 -s 10 $TMPDIR/maschineLP.bmp"
	end try
	
	# get offset to start of pixel array from the BMP file
	set bmp_offset to fromHex(output)
	
	# check if retina then double pixel size of patterns		
	set dpi to do shell script "xxd -p -l 4 -s 38 $TMPDIR/maschineLP.bmp"
	if dpi = "25160000" then
		set pixel_size to 2
		set bmp_dx to dx * 2
		set bmp_dy to dy * 2
	else
		set pixel_size to 1
		set bmp_dx to dx
		set bmp_dy to dy
	end if
	
	# now prepare commands that will extract relevant pixel colors for patterns from the BMP file
	set commands to ""
	set bmp_row_bytes to ((gridx - 1) * bmp_dx + pixel_size * 2) * 4
	repeat with iy from 1 to gridy
		repeat with ix from 1 to gridx
			set array_offset to (iy - 1) * bmp_dy * bmp_row_bytes + (ix - 1) * bmp_dx * 4
			set commands to commands & "xxd -p -l 11 -s " & (bmp_offset + array_offset) & " $TMPDIR/maschineLP.bmp"
			if (iy < gridy) or (ix < gridx) then set commands to commands & " && "
		end repeat
	end repeat
	
	try
		set output to do shell script commands
	end try
	
	# convert shell script output to a usable form (i.e. rows of rgb colors in dec format)
	set bgr_colors to paragraphs of output
	set rgb_colors to {}
	repeat with iy from 1 to gridy
		set row to {}
		repeat with ix from 1 to gridx
			set i to (iy - 1) * gridx + ix
			set bgr to item i of bgr_colors
			
			# check if this is the currently selected pattern
			# (i.e. if it has a white outline
			if text 1 thru 6 of bgr = "ffffff" then
				set selected_pattern to {offsetx + ix, offsety + iy}
				
				# shift to next pixel to check for colour
				set bgr to text 17 thru 22 of bgr
			end if
			
			set r to fromHex(text 5 thru 6 of bgr)
			set g to fromHex(text 3 thru 4 of bgr)
			set b to fromHex(text 1 thru 2 of bgr)
			set row to row & {{r, g, b}}
		end repeat
		set rgb_colors to rgb_colors & {row}
	end repeat
	
	return rgb_colors
	
end getMaschinePatternColors

# ------------------------------------------------------------

# handler getMaschineScenes()
# reads the status of first two scenes in Maschine
# returns two numbers – {active_scene, s2_exists}
# active_scene is the number of the active scene
# s2_exists is 1 if Scene 2 exists and 0 if it doesn't

on getMaschineScenes()
	set {x, y} to getMaschinePatternsPosition()
	set active_scene to 0
	set s2_exists to 0
	
	# coordinates for scene button 1 (just before the title of button 1 'scene 1')
	set x to x + 20
	set y to y - 30
	
	set sizex to 2 * dx # wide enough to scan scenes 1 and 2 – we don't care about any further scenes
	set sizey to 1 # we only need one row for the scenes
	
	try
		# take screen capture of Maschine scenes - first two scenes only
		set output to do shell script "screencapture -x -R" & x & "," & y & "," & sizex & "," & sizey & " -t bmp $TMPDIR/maschineLP.bmp && xxd -p -l 1 -s 10 $TMPDIR/maschineLP.bmp"
	end try
	
	# get offset to start of pixel array from the BMP file
	set bmp_offset to fromHex(output)
	
	# check if retina then double pixel size of patterns		
	set dpi to do shell script "xxd -p -l 4 -s 38 $TMPDIR/maschineLP.bmp"
	if dpi = "25160000" then
		set pixel_size to 2
	else
		set pixel_size to 1
	end if
	
	# pixels for scene 2 start at an offset from the start of the pixel array
	set scene2_offset to dx * pixel_size * 4
	
	# grab 50 pixels (200 bytes) for scene 1, then 50 pixels for scene 2 
	# note that 50 pixlels is not a lot on retina
	# tr is used to remove 'new line' from the output of xxd
	set s1_pixels to do shell script "xxd -p -l 200 -s " & (bmp_offset) & " $TMPDIR/maschineLP.bmp | tr -d '
'"
	set s2_pixels to do shell script "xxd -p -l 200 -s " & (bmp_offset + scene2_offset) & " $TMPDIR/maschineLP.bmp | tr -d '
'"
	set scenes_pixels to {s1_pixels, s2_pixels}
	
	# check which scene is active
	repeat with i from 1 to 2
		set bgr to text 1 thru 6 of item i of scenes_pixels
		if bgr is "4f4f4f" then set active_scene to i
	end repeat
	
	# check if scene 2 exists - scan 50 pixels for colours,
	# skipping every second pixel as they're the same on retina
	repeat with i from 1 to 25
		set bgr to text ((i - 1) * 8 * 2 + 1) thru ((i - 1) * 8 * 2 + 6) of s2_pixels
		# set bgr to text 17 thru 22 of s2_pixels
		set r to fromHex(text 5 thru 6 of bgr)
		set g to fromHex(text 3 thru 4 of bgr)
		set b to fromHex(text 1 thru 2 of bgr)
		if (r is not g) or (g is not b) then
			set s2_exists to 1
		end if
	end repeat
	
	return {active_scene, s2_exists}
end getMaschineScenes

# ------------------------------------------------------------

# handler clickMaschinePattern(patx, paty)
# return true if new pattern is created, otherwise false

on clickMaschinePattern(patx, paty)
	# get current pad color and intensity
	set LPcolor to item patx of item paty of mas_pattern_colors
	set intensity to getLPintensity(LPcolor)
	
	# if click is on an empty pattern there are two scenarios
	# first turn all patterns in that group off
	# second (if the 'user' pad is being held) create a new pattern (requires double click)
	set create_new to false
	if intensity is 0 then
		# check if another pattern in column is active and deactivate it
		repeat with iy from 1 to 8
			set LPcolor to item patx of item iy of mas_pattern_colors
			if getLPintensity(LPcolor) is active then clickMaschinePattern(patx, iy)
		end repeat
		
		# if user key is being held and click is on empty pattern, create new pattern
		if user_pad is true then set create_new to true
	end if
	
	# find coordinates to click on
	set {x, y} to getMaschinePatternsPosition()
	set x to x + (patx - 1) * dx
	set y to y + (paty - 1) * dy
	
	# check if double click required (e.g. when pattern active, but not selected)	
	if intensity is active and item 1 of selected_pattern is not patx then
		try
			# repeating a click twice (c) is faster than double click (dc)
			# this is better for faster pattern switching
			do shell script "/usr/local/bin/cliclick c:" & x & "," & y & " c:" & x & "," & y
		end try
	else if create_new is true then
		try
			# creating a new pattern requires a slower double click
			do shell script "/usr/local/bin/cliclick dc:" & x & "," & y
		end try
	else
		try
			do shell script "/usr/local/bin/cliclick c:" & x & "," & y
		end try
	end if
	
	# set selected to current pattern – except if we've turned it off
	set selected_pattern to {patx, paty}
	if intensity is active then set selected_pattern to {0, 0}
	
	return create_new
	
end clickMaschinePattern


# ------------------------------------------------------------

# handler clickMaschineRow(rowy)
# activate all existing patterns on selected row
# similar to how scene selection works in Ableton Live

on clickMaschineRow(rowy)
	set commands to "" # we'll store the cliclick mouse click commands here
	set {basex, basey} to getMaschinePatternsPosition() # starting coordinates for clicks
	repeat with ix from 1 to 8
		# check status of pattern in selected row in column ix (column representing a Maschine group)
		set pattern_intensity to getLPintensity(item ix of item rowy of mas_pattern_colors)
		
		# check if any other patterns in column (Maschine group) ix are active
		set any_in_group_active to false
		set active_y to 0
		repeat with iy from 1 to 8
			if getLPintensity(item ix of item iy of mas_pattern_colors) = active then
				set any_in_group_active to true
				set active_y to iy
			end if
		end repeat
		
		# only do stuff if anything in the column needs changing
		
		if pattern_intensity is inactive then
			# find coordinates to click on
			set x to basex + (ix - 1) * dx
			set y to basey + (rowy - 1) * dy
			# single click should do it
			set commands to commands & " c:" & x & "," & y
			set selected_pattern to {ix, rowy}
		end if
		
		if pattern_intensity is 0 and any_in_group_active is true then
			# find coordinates to click on
			set x to basex + (ix - 1) * dx
			set y to basey + (active_y - 1) * dy
			if item 1 of selected_pattern is ix then
				# single click if selected group
				set commands to commands & " c:" & x & "," & y
			else
				# if group not selected then double click
				set commands to commands & " c:" & x & "," & y & " c:" & x & "," & y
			end if
			set selected_pattern to {ix, active_y}
		end if
	end repeat
	
	# run all the clicks with cliclick
	try
		do shell script "/usr/local/bin/cliclick" & commands
	end try
	
end clickMaschineRow


# ------------------------------------------------------------

# handler switchScene(row)
# swap from scene 1 to 2 or the other way around
# if row is 0 then reselect activate patterns from previous scene
# if row is 1 then activate all patterns in a row

on switchScene(row)
	set clicks to ""
	
	set {basex, basey} to getMaschinePatternsPosition() # starting coordinates for clicks
	set x to basex
	set y to basey - dy # above the pattern grid
	
	if s2_exists is 0 then
		# add click to create scene 2 if it doesn't exist yet	
		set clicks to " c:" & x + dx & "," & y
		set s2_exists to 1
		set active_scene to 2
	else
		# else switch scenes and clear (right click thenclick clear in submenu)
		set clicks to " kd:ctrl c:" & x + (active_scene mod 2) * dx & "," & y & " ku:ctrl c:+50,+60"
		set active_scene to (active_scene mod 2) + 1 # swap 1 to 2 or other way around
	end if
	
	# re-select same patterns as before (in previous scene)
	if row is 0 then
		repeat with ix from 1 to 8
			repeat with iy from 1 to 8
				if getLPintensity(item ix of item iy of mas_pattern_colors) is active then
					set x to basex + (ix - 1) * dx
					set y to basey + (iy - 1) * dy
					set clicks to clicks & " c:" & x & "," & y
				end if
			end repeat
		end repeat
	end if
	
	# if we're activating all existing patterns in the same row
	if row > 0 then
		set iy to row
		repeat with ix from 1 to 8
			# only activate if pattern exists
			if getLPintensity(item ix of item iy of mas_pattern_colors) is not 0 then
				set x to basex + (ix - 1) * dx
				set y to basey + (iy - 1) * dy
				set clicks to clicks & " c:" & x & "," & y
			end if
		end repeat
	end if
	
	# run the clicks
	try
		do shell script "/usr/local/bin/cliclick " & clicks
	end try
end switchScene



# ------------------------------------------------------------
# ---------------------- MAIN HANDLER --------------
# ------------------------------------------------------------

on runme(message)
	# check for maschine instances
	if (maschine_app or maschine_logic or maschine_live) is false then findMaschineInstances()
	
	# only do anything if the Maschine window is actually open
	if (maschine_app or maschine_logic or maschine_live) then
		
		if legacy then set padNumbers to padNumbersLegacy
		
		# ------------ SESSION BUTTON -------------
		if (item 1 of message = 176) and (item 2 of message = 95) and (item 3 of message > 0) then
			set message to {}
			
			findMaschineInstances() # check if anything has changed
			set masColors to getMaschinePatternColors(8, 8, 0, 0)
			repeat with iy from 1 to 8
				repeat with ix from 1 to 8
					set rgb to item ix of item iy of masColors
					set message to message & setLPcolor(ix, iy, rgbToLPcolor(item 1 of rgb, item 2 of rgb, item 3 of rgb))
				end repeat
			end repeat
			
			# check status of scenes
			set {active_scene, s2_exists} to getMaschineScenes()
			
			return message
		end if
		
		
		# ------- IF LEGACY MODE THEN REMAP BUTTONS IN RIGHT-MOST ROW ----- 
		if legacy then
			if (item 1 of message = 144) and (item 2 of message ≥ 100) and (item 3 of message > 0) then
				set new_value to (8 - ((item 2 of message) - 100)) * 10 + 9
				set message to {176, new_value, item 3 of message}
			end if
		end if
		
		# ------------ NOTE ON -------------
		if (item 1 of message = 144) and (item 3 of message > 0) then
			set {padx, pady} to getLPpadXY(item 2 of message)
			set message to {}
			
			# switch scenes if the keys pad is pressed – but only do it once
			if keys_pad then
				switchScene(0)
				set keys_pad to false
			end if
			
			set is_new_pattern to clickMaschinePattern(padx, pady)
			
			# toggle pad color for selected pattern
			set oldLPcolor to item padx of item pady of mas_pattern_colors
			set oldIntensity to getLPintensity(oldLPcolor)
			if oldIntensity = inactive then
				set message to message & setLPcolor(padx, pady, setLPintensity(oldLPcolor, active))
			end if
			if oldIntensity = active then
				set message to message & setLPcolor(padx, pady, setLPintensity(oldLPcolor, inactive))
			end if
			
			# set pad colors for other patterns in column to inactive
			repeat with iy from 1 to 8
				set oldLPcolor to item padx of item iy of mas_pattern_colors
				if (oldLPcolor is not 0) and (iy is not pady) then
					set message to message & setLPcolor(padx, iy, setLPintensity(oldLPcolor, inactive))
				end if
			end repeat
			
			# if a new pattern was created, turn it on
			if is_new_pattern then
				set masColors to getMaschinePatternColors(1, 1, padx - 1, pady - 1)
				set rgb to item 1 of item 1 of masColors
				set message to message & setLPcolor(padx, pady, rgbToLPcolor(item 1 of rgb, item 2 of rgb, item 3 of rgb))
			end if
			
			return message
		end if
		
		# ------------ NOTE OFF -------------
		if (item 1 of message = 144) and (item 3 of message = 0) then
			set message to {}
		end if
		
		# ------------ KEYS PAD ON -------------
		if (item 1 of message = 176) and (item 2 of message = 97) and (item 3 of message = 127) then
			set keys_pad to true
		end if
		
		# ------------ KEYS PAD OFF -------------
		if (item 1 of message = 176) and (item 2 of message = 97) and (item 3 of message = 0) then
			set keys_pad to false
		end if
		
		# ------------ USER PAD ON -------------
		if (item 1 of message = 176) and (item 2 of message = 98) and (item 3 of message = 127) then
			set user_pad to true
		end if
		
		# ------------ USER PAD OFF -------------
		if (item 1 of message = 176) and (item 2 of message = 98) and (item 3 of message = 0) then
			set user_pad to false
		end if
		
		# ------------ SCENE KEYS -------------
		# when scene key is pressed, activate all patterns on that row
		if (item 1 of message = 176) and ((item 2 of message) mod 10 = 9) and (item 3 of message = 127) then
			set pady to 9 - ((item 2 of message) div 10)
			set message to {}
			
			if keys_pad then
				# use the switch scenes function if the keys pad is pressed
				switchScene(pady)
			else
				# otherwise use 'clickmaschinerow' to activate the right patterns in existing scene
				clickMaschineRow(pady)
			end if
			
			# grab current state from Maschine with a new screengrab
			set masColors to getMaschinePatternColors(8, 8, 0, 0)
			repeat with iy from 1 to 8
				repeat with ix from 1 to 8
					set rgb to item ix of item iy of masColors
					set message to message & setLPcolor(ix, iy, rgbToLPcolor(item 1 of rgb, item 2 of rgb, item 3 of rgb))
				end repeat
			end repeat
		end if
		
		return message
		
		# for debugging use
		# do shell script "echo " & intensity & " >> $TMPDIR/mas_temp.txt"
		
	end if
end runme