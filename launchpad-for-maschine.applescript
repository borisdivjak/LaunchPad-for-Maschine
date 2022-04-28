# This is a MidiPipe AppleScript for MacOS that enables Native Instruments 
# Maschine 2 users to use a Novation LaunchPad MK3 Mini to control patterns 
# and loops in Maschine.
#
# When pads on the LaunchPad Mini are pressed, they are passed as 
# MIDI messages through MidiPipe (http://www.subtlesoft.square7.net/MidiPipe.html) 
# to this script that translates those messages into mouse movements and clicks 
# to control Maschine. 
#
# The script uses 'Cliclick'(https://github.com/BlueM/cliclick), 
# a command line utility to control mouse clicks as well as MacOS's own 'screencapture' 
# to read the status of the patterns and other interface elements in Maschine
#
# This script was inspired by a hack posted by D-One on the Native Instruments forum:
# https://www.native-instruments.com/forum/threads/kinda-hacked-machine-ideas-view-for-external-midi-pattern-selection.316506/
#
# Check the GitHub page for more detail and instructions

use framework "Foundation"
use scripting additions

property cliclick : "/Applications/cliclick"

property firstx : 356 # 'x' where patterns start in Maschine
property firstx_no_browser : 30 # with instrument browser closed
property firsty : 80 # 'y' where patterns start in Maschine
property dx : 99 # width of pattern slots in Maschine
property dy : 22 # height of pattern slots in Maschine

property active : 3 # LaunchPad intentisty to use for active patterns
property inactive : 1 # LaunchPad intentisty to use for inactive patterns
property session_pad : false # state of 'session' pad on LaunchPad – false until pressed
property drums_pad : false # state of 'drums' pad on LaunchPad – false until pressed
property keys_pad : false # state of 'keys' pad on LaunchPad – false until pressed
property user_pad : false # state of 'user' pad on LaunchPad – false until pressed

# properties that store whether maschine is used standalone or as VST in Logic / Live
# these are automatically set when 'session' is pressed
property maschine_app : false
property maschine_plug : 0
property maschine_plug_options : {"Live", "Logic Pro X"}

# you may wish to run the patterns in monochrome / grayscale – if so, set this to true
property grayscale : false
property gray_inactive : 103 # LP color used for inactive state in grayscale mode

# mapping of pads on LaunchPad - starting with top left corner and going row by row
property padNumbers : {{81, 82, 83, 84, 85, 86, 87, 88}, {71, 72, 73, 74, 75, 76, 77, 78}, {61, 62, 63, 64, 65, 66, 67, 68}, {51, 52, 53, 54, 55, 56, 57, 58}, {41, 42, 43, 44, 45, 46, 47, 48}, {31, 32, 33, 34, 35, 36, 37, 38}, {21, 22, 23, 24, 25, 26, 27, 28}, {11, 12, 13, 14, 15, 16, 17, 18}}

# mapping of LauchPad buttons in top row
property ctrlButtons : {91, 92, 93, 94, 95, 96, 97, 98}


# these propeties will store current state of maschine patterns and scenes:

property active_scene : 0
property s2_exists : 0
property selected_pattern : {0, 0}

# used to store current state of LaunchPad colors
property mas_pattern_colors : {{0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0, 0, 0}}

# used to store position of maschine window
property maschine_x : -1
property maschine_y : -1
property maschine_sizex : -1
property maschine_sizey : -1
property paddingx : 0
property paddingy : 0
property browser_on : true # status of instrument browser – checked automatically

# used to store timestamp (to check time between events)
property lasttime : 0



# collection of helper handlers/functions:


# handler sinceLastTime()
# retrieves current timestamp and stores it in the property lasttime
# returns time since last time this handler was called in milliseconds
# if update is true then updates the lasttime property with new time

on sinceLastTime(update)
	set now to current application's class "NSDate"'s |date|()
	set dateFormatter to current application's class "NSDateFormatter"'s new()
	tell dateFormatter to setDateFormat:("HH mm ss SSS")
	set timeStamp to (dateFormatter's stringFromDate:(now)) as text
	
	# convert all to milliseconds
	set x to word 4 of timeStamp
	set x to x + (word 3 of timeStamp) * 1000
	set x to x + (word 2 of timeStamp) * 1000 * 60
	set x to x + (word 1 of timeStamp) * 1000 * 60 * 60
	
	set dif to x - lasttime
	if update then set lasttime to x
	return dif
end sinceLastTime


# ------------------------------------------------------------

# handler list2string(theList, theDelimiter)
# turn an applsecript list into text (string) separated by the delimiter

on list2string(theList, theDelimiter)
	
	-- First, we store in a variable the current delimiter to restore it later
	set theBackup to AppleScript's text item delimiters
	
	-- Set the new delimiter
	set AppleScript's text item delimiters to theDelimiter
	
	-- Perform the conversion
	set theString to theList as string
	
	-- Restore the original delimiter
	set AppleScript's text item delimiters to theBackup
	
	return theString
	
end list2string


# ------------------------------------------------------------

# handler screenGrab(x, y, sizex, sizey)
# do a screengrab and save in temp file
# to be used in combination with pixelStream handler – see below

on screenGrab(x, y, sizex, sizey)
	# only do anything if maschine is open	
	if maschine_app or (maschine_plug > 0) then
		# bring window to front so we can take screengrab – either maschine app or plugin host
		if maschine_app then activate application "Maschine 2"
		
		# for some reason the below line doesn't work well with Live - so keeping it as comment
		# if maschine_plug > 0 then activate application (item maschine_plug of maschine_plug_options)
		
		# always measure grab from top left corner of maschine window
		set x to x + maschine_x - 1
		set y to y + maschine_y - 1
		try
			set output to do shell script "screencapture -x -R" & x & "," & y & "," & sizex & "," & sizey & " -t bmp $TMPDIR/maschineLP.bmp"
		end try
	end if
end screenGrab


# ------------------------------------------------------------

# handler pixelStream(x, y, sizex, sizey, options)
# return stream of pixels from the caputred BMP ($TMPDIR/maschineLP.bmp)
# - does't do the capture itelf - to capture see 'screenGrab' above
# - coordinates refer to the captured image, not the edge of the screen
# - options specify a selection pattern - format {includex, gapx, includey, gapy} or leave empty for all {}

on pixelStream(x, y, sizex, sizey, options)
	set output to do shell script "od -An -t dI -j 10 -N 32 -v $TMPDIR/maschineLP.bmp"
	
	# get offset to start of pixel array from the BMP file
	set bmp_offset to (word 1 of output) as integer
	set bmp_width to (word 3 of output) as integer
	set bmp_height to (word 4 of output) as integer
	# note that the height in BMP is negative to indicite top to bottom progression
	# but the word operator strips the negative sign away
	
	# if we're asking for something out of bounds of the image, return nothing
	if (bmp_width < (x + sizex - 1)) or (bmp_height < (y + sizey - 1)) then return ""
	
	# check if retina then double pixel size of patterns		
	set dpi to word 8 of output
	if dpi = "5669" then
		set pixel_size to 2
		set awk_filter_retina to " | awk '{print $2, $4}'" # grab every second pixel
	else
		set pixel_size to 1
		set awk_filter_retina to " | awk '{print $1, $2, $3, $4}'" # grab every pixel
	end if
	
	if options is {} then
		set includex to sizex
		set gapx to 0
		set includey to sizey
		set gapy to 0
	else
		set includex to item 1 of options
		set gapx to item 2 of options
		set includey to item 3 of options
		set gapy to item 4 of options
	end if
	
	
	# caluculate where we need to start grabbing pixels - which line	
	set bytes_per_pixel to pixel_size * 4
	set bytes_per_row to bmp_width * bytes_per_pixel
	set bmp_offset to bmp_offset + (y - 1) * bytes_per_row
	
	# we'll store the shell commands to extract pixel values from bmp here
	# writing it all as one long pipe call so it executes faster
	set commands to ""
	
	repeat with gridy from 1 to sizey by (includey + gapy)
		repeat with iy from gridy to (gridy + includey - 1)
			
			# offset from start of pixel array to where the next line begins
			set array_offset to (iy - 1) * bytes_per_row + (x - 1) * bytes_per_pixel
			
			# use od to grab a line of pixels (byte length sizex * bytes_per_pixel)
			# we're executing these commands in parallel (using the & operator) so they're faster
			set commands to commands & "( od -t xI -j " & (bmp_offset + array_offset) & " -N " & sizex * bytes_per_pixel & " -v $TMPDIR/maschineLP.bmp | grep '.*' --line-buffered ) & "
		end repeat
	end repeat
	
	# if pattern options are specified add one more command to filter each line
	# to find the right pixels – grab 'includex' pixels, then skip 'gapx' then grab 'includex' then skip ...
	# and repeat until the end		
	if options is {} then
		set awk_filter_x to ""
	else
		# this will filter the appropriate pixels on the horizontal axis
		set awk_filter_x to " | awk '(FNR-1) % " & (includex + gapx) & " < " & includex & "'"
	end if
	
	# exectue commands to grab all the image pixels
	# sort -k1 sorts the output into the right order as we're executing reads in parallel to be faster
	# awk -v OFS='\\n' '{$1=$1}1' puts each pixel in a new line - one pixel per line
	# awk 'NF'removes any blank lines
	set pixels to do shell script "{ " & commands & " } | sort -k1" & awk_filter_retina & " | awk -v OFS='\\n' '{$1=$1}1' | awk 'NF'" & awk_filter_x
	
	return pixels
end pixelStream


# ------------------------------------------------------------

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
	set hue to rgbToHue(r, g, b) / 25.714 - 0.5
	set hue to round hue
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

# handler setLPcolor(padx, pady, LPcolor)
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
	if grayscale and intensity is inactive then set LPcolor to gray_inactive # for grayscale mode
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

# handler showLPControlButtons()
# lights up the relevant buttons in LaunchPad's top row
# i.e. 'session', 'keys' and 'user'
# returns MIDI message to send to LaunchPad

on showControlButtons()
	set LPcolor_inactive to 11 # dim orange
	set LPcolor_active to 3 # white
	if grayscale then set LPcolor_inactive to gray_inactive
	
	# set 'session' button	
	if session_pad is true then
		set msg to {176, item 5 of ctrlButtons, 3}
	else
		set msg to {176, item 5 of ctrlButtons, 1}
	end if
	
	# set 'drums' button
	if drums_pad is true then
		set msg to msg & {176, item 6 of ctrlButtons, 5} # lights up red 
	else
		set msg to msg & {176, item 6 of ctrlButtons, LPcolor_inactive}
	end if
	
	# set 'keys' button - active and inactive variation
	if keys_pad is true then
		set msg to msg & {178, item 7 of ctrlButtons, LPcolor_active}
	else
		# use message 178 for a pulsating color
		set msg to msg & {176, item 7 of ctrlButtons, LPcolor_inactive}
	end if
	
	# set 'user' button
	if user_pad is true then
		set msg to msg & {176, item 8 of ctrlButtons, LPcolor_active}
	else
		set msg to msg & {176, item 8 of ctrlButtons, LPcolor_inactive}
	end if
	
	return msg
	
end showControlButtons



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
# return 0 if nothing found, 1 if same position / size as before and 2 if anything changed

on findMaschineInstances()
	set status to 0
	set {old_maschine_x, old_maschine_y} to {maschine_x, maschine_y}
	set {old_sizex, old_sizey} to {maschine_sizex, maschine_sizey}
	set {maschine_x, maschine_y} to {-1, -1}
	
	tell application "System Events"
		
		# APP - check if maschine standalone app is running	
		set maschine_app to (name of processes) contains "Maschine 2"
		set maschine_plug to 0 # reset the plugin status property
		
		if maschine_app then
			set {maschine_x, maschine_y} to position of first window of process "Maschine 2"
			set {maschine_sizex, maschine_sizey} to size of first window of process "Maschine 2"
			
		else
			
			# PLUG-IN - if not the app, then check if a plugin version is open		
			repeat with i from 1 to count of maschine_plug_options
				set host_app to item i of maschine_plug_options
				if ((name of processes) contains item i of maschine_plug_options) ¬
					and (count of (windows of process host_app ¬
					whose name contains "maschine")) is not 0 then
					
					set maschine_plug to i
					set {maschine_x, maschine_y} to position of (first item of (windows of process host_app whose name contains "maschine"))
					set {maschine_sizex, maschine_sizey} to size of (first item of (windows of process host_app whose name contains "maschine"))
				end if
			end repeat
		end if
	end tell
	
	if maschine_app or (maschine_plug > 0) then set status to 1
	if {old_maschine_x, old_maschine_y, old_sizex, old_sizey} is not ¬
		{maschine_x, maschine_y, maschine_sizex, maschine_sizey} then set status to 2
	return status
	
end findMaschineInstances


# ------------------------------------------------------------

# handler getMaschineInnerPosition()
# takes a screengrab of the left top corner of Maschine and finds 
# the detailed position of the inner window – this is important
# as the window header and borders can have a different size depending
# on the host when maschine is used as a plugin
#
# we also check for the instrument 'browser' – if this is open the pattern 
# position is different
#
# sets properties paddingx, paddingy and browser_on


on getMaschineInnerPosition()
	# check if app or plugin window present
	if maschine_app or (maschine_plug > 0) then
		
		# set coordinates for a vertical slice/screenshot to check where maschine window begins
		# if it's the app we have a bit more certainty so tighter parameters
		if maschine_app then # if maschine app
			set v_slice_start to 28
			set v_slice_height to 18
			
			# if full-screen - then the starting edge is at the very top
			if (maschine_x = 0) and (maschine_y = 0) then set v_slice_start to 1
			
		else # if maschine plugin
			set v_slice_start to 10
			set v_slice_height to 120
		end if
		
		# find position for first screengrab - to assess the height of the window header
		set width to 245
		if maschine_sizex < 1305 then set width to 92 # if smaller window / logo collapsed
		
		# capture the screenshot
		screenGrab(1, v_slice_start, width, v_slice_height)
		# get a vertical slice of pixels just above the 'browser' icon - to identify where the window header ends
		set x to width
		set y to 1
		set pixels to pixelStream(x, 1, 1, v_slice_height, {})
		set pixels to list2string(paragraphs of pixels, "")
		
		# signature to look for – 3 black pixels + 4 grey
		set signature to "ff000000ff000000ff000000ff5e5e5eff585858ff575757ff565656"
		
		# find top offset – how many pixels below window header does maschine actually begin
		set paddingy to -1
		repeat with i from 1 to (((count of pixels) - (count of signature)) / 8)
			set char_i to ((i - 1) * 8 + 1)
			set pixel_group to text char_i thru (char_i + (count of signature) - 1) of pixels
			if pixel_group begins with signature then set paddingy to i
		end repeat
		
		# check if 'browser' icon is on
		# start by selecting the group of pixels around the icon
		set char_i to ((paddingy - 1) * 8 + 1)
		set pixel_group to text char_i thru (char_i + 15 * 8) of pixels
		
		# then check if any of them are white - and set the browser_on accordingly
		set browser_on to (pixel_group contains "ffffffff" or pixel_group contains "fffefefe")
		
		# with the next screengrab assess if any padding on the left of the window
		# check the pixels just above the logo on the left edge
		set x to 1
		set y to paddingy + 5
		set pixels to pixelStream(x, y, 20, 1, {})
		set pixels to list2string(paragraphs of pixels, "")
		
		# signature to look for – 2 black pixels + 4 grey
		set signature to "ff000000ff000000ff565656ff575757ff575757ff575757"
		
		# find left offset – how manyve border pixels does the window have
		set paddingx to -1
		repeat with i from 1 to (((count of pixels) - (count of signature)) / 8)
			set char_i to ((i - 1) * 8 + 1)
			set pixel_group to text char_i thru (char_i + (count of signature) - 1) of pixels
			if pixel_group begins with signature then set paddingx to i
		end repeat
		
		# add the initial offset to padding
		set paddingy to paddingy + v_slice_start - 1
		
	end if
end getMaschineInnerPosition


# ------------------------------------------------------------

# handler getMaschineBrowserStatus()
# returns true if browser on and false if not
# also sets the browser_on property

on getMaschineBrowserStatus()
	if maschine_app or (maschine_plug > 0) then
		# find position for first screengrab - to assess the height of the window header
		set x to 246
		if maschine_sizex < 1305 then set x to 93 # if smaller window / logo collapsed
		screenGrab(paddingx + x, paddingy + 18, 10, 10)
		set pixels to pixelStream(1, 1, 1, 1, {})
		set browser_on to false
		if pixels is "ffffffff" then set browser_on to true
		return browser_on
	end if
	return false
end getMaschineBrowserStatus

# ------------------------------------------------------------

# handler getMaschinePatternsPosition()
# returns the starting X and Y for maschine patterns relative to maschine window
# note that the starting point needs to be inside the pattern 
# (the color of the starting pixel will represent the first pattern)

on getMaschinePatternsPosition()
	# if no Maschine window was found, return -1	
	if (maschine_app or (maschine_plug > 0)) is false then return {-1, -1}
	
	set x to firstx + paddingx
	set y to firsty + paddingy
	
	# if instrument browser is closed
	if browser_on is false then set x to firstx_no_browser + paddingx
	
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
	
	set sizex to gridx * dx
	set sizey to gridy * dy
	
	
	screenGrab(x, y, sizex, sizey)
	set output to pixelStream(1, 1, sizex, sizey, {2, dx - 2, 1, dy - 1})
	
	# convert shell script output to a usable form (i.e. rows of rgb colors in dec format)
	set hex_colors to paragraphs of output
	set rgb_colors to {}
	repeat with iy from 1 to gridy
		set row to {}
		repeat with ix from 1 to gridx
			set i to ((iy - 1) * gridx + ix) * 2 - 1 # check every second pixel
			set hex to item i of hex_colors
			
			# check if this is the currently selected pattern
			# (i.e. if it has a white outline)
			if text 3 thru 8 of hex = "ffffff" then
				set selected_pattern to {offsetx + ix, offsety + iy}
				
				# shift to next pixel to check for colour
				set hex to item (i + 1) of hex_colors
			end if
			
			set r to fromHex(text 3 thru 4 of hex)
			set g to fromHex(text 5 thru 6 of hex)
			set b to fromHex(text 7 thru 8 of hex)
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
	
	screenGrab(x, y, sizex, sizey)
	set output to pixelStream(1, 1, sizex, sizey, {25, dx - 25, 1, 0})
	
	set s1_pixels to paragraphs 1 thru 25 of output
	set s2_pixels to paragraphs 26 thru 50 of output
	
	set scenes_pixels to {s1_pixels, s2_pixels}
	
	# check which scene is active – which one is the brigther grey color
	repeat with i from 1 to 2
		set hex to item 1 of item i of scenes_pixels
		if hex is "ff4f4f4f" then set active_scene to i
	end repeat
	
	# check if any of the pixels in the scene 2 area are not grey (the scene title is always in color)
	repeat with hex in items of s2_pixels
		set r to fromHex(text 3 thru 4 of hex)
		set g to fromHex(text 5 thru 6 of hex)
		set b to fromHex(text 7 thru 8 of hex)
		if (r is not g) or (g is not b) then set s2_exists to 1
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
	set active_pattern to 0
	if intensity is 0 then
		# check if another pattern in column is active and deactivate it
		repeat with iy from 1 to 8
			set LPcolor to item patx of item iy of mas_pattern_colors
			if getLPintensity(LPcolor) is active then set active_pattern to iy
			#			if getLPintensity(LPcolor) is active then clickMaschinePattern(patx, iy)
		end repeat
		
		# if user key is being held and click is on empty pattern, create new pattern
		if drums_pad is true then set create_new to true
	end if
	
	set clicks to ""
	
	# find coordinates to click on
	set {x, y} to getMaschinePatternsPosition()
	set x to x + maschine_x + (patx - 1) * dx
	set y to y + maschine_y + (paty - 1) * dy
	
	
	# set coordinates to click on - the pattern we're deactivating
	set {x, y} to getMaschinePatternsPosition()
	set x to x + maschine_x + (patx - 1) * dx
	set y to y + maschine_y + (active_pattern - 1) * dy
	
	# if we're muting a pattern - check first if column selected or not
	if intensity is 0 and active_pattern > 0 then
		if item 1 of selected_pattern is patx then
			# in the selected column we can deactivate with a single click
			set clicks to clicks & " c:" & x & "," & y
		else
			# in a non-selected column we need a double click to deactivate
			# we're repeating the 'c' command rather than using 'dc' as this is faster
			set clicks to clicks & " c:" & x & "," & y & " c:" & x & "," & y
		end if
	end if
	
	
	# set coordinates to click on - the pattern we're selecting
	set {x, y} to getMaschinePatternsPosition()
	set x to x + maschine_x + (patx - 1) * dx
	set y to y + maschine_y + (paty - 1) * dy
	
	# if creating new pattern, add double click
	if create_new is true then set clicks to clicks & " dc:" & x & "," & y
	
	# if we're activating an inactive pattern then add normal click
	if intensity is inactive then set clicks to clicks & " c:" & x & "," & y
	
	# if we're selected an active pattern that's not currently selected, single click will do
	if intensity is active and item 1 of selected_pattern is not patx then set clicks to clicks & " c:" & x & "," & y
	
	
	# execute clicks
	try
		do shell script cliclick & " " & clicks
	end try
	
	# set selected to current pattern
	set selected_pattern to {patx, paty}
	
	return create_new
	
end clickMaschinePattern


# ------------------------------------------------------------

# handler clickMaschineRow(rowy)
# activate all existing patterns on selected row
# similar to how scene selection works in Ableton Live

on clickMaschineRow(rowy)
	set commands to "" # we'll store the cliclick mouse click commands here
	set {basex, basey} to getMaschinePatternsPosition() # starting coordinates for clicks
	set basex to basex + maschine_x
	set basey to basey + maschine_y
	set previously_selected to selected_pattern
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
	
	# return to the group that was selected before (if not there already)
	if item 1 of selected_pattern is not item 1 of previously_selected then
		set x to basex + ((item 1 of previously_selected) - 1) * dx
		set y to basey + (rowy - 1) * dy
		set commands to commands & " c:" & x & "," & y
		set item 1 of selected_pattern to item 1 of previously_selected
	end if
	
	# run all the clicks with cliclick
	try
		do shell script cliclick & commands
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
	set basex to basex + maschine_x
	set basey to basey + maschine_y
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
					set selected_pattern to {ix, iy}
				end if
			end repeat
		end repeat
	end if
	
	# if we're activating all existing patterns in the same row
	if row > 0 then
		set previously_selected to selected_pattern
		set iy to row
		repeat with ix from 1 to 8
			# only activate if pattern exists
			if getLPintensity(item ix of item iy of mas_pattern_colors) is not 0 then
				set x to basex + (ix - 1) * dx
				set y to basey + (iy - 1) * dy
				set clicks to clicks & " c:" & x & "," & y
				set selected_pattern to {ix, iy}
			end if
		end repeat
		
		# return to the group that was selected before (if not there already)
		if item 1 of selected_pattern is not item 1 of previously_selected then
			set x to basex + ((item 1 of previously_selected) - 1) * dx
			set y to basey + (iy - 1) * dy
			set clicks to clicks & " c:" & x & "," & y
			set item 1 of selected_pattern to item 1 of previously_selected
		end if
	end if
	
	# run the clicks
	try
		do shell script cliclick & " " & clicks
	end try
end switchScene



# ----------------------------------------------------------------------------
# ---------------------- MAIN HANDLER FOR MIDI MESSAGES ----------
# ----------------------------------------------------------------------------

on runme(message)
	# if message is not note on or cc change then ignore
	if {144, 176, 153} does not contain item 1 of message then return {}
	
	# check for maschine instances
	if (maschine_app or (maschine_plug > 0)) is false then findMaschineInstances()
	
	# only do anything if the Maschine window is actually open
	if (maschine_app or (maschine_plug > 0)) then
		
		
		# ------------ AUTO SCENE CHANGE MESSAGE -------------
		# i.e. if scene change MIDI message received from maschine
		if item 1 of message is 153 and item 2 of message < 16 then
			# only refresh if it was recent
			if sinceLastTime(false) > 500 then
				
				# check maschine patterns and light LP pads appropraitely
				set masColors to getMaschinePatternColors(8, 8, 0, 0)
				repeat with iy from 1 to 8
					repeat with ix from 1 to 8
						set rgb to item ix of item iy of masColors
						set message to message & setLPcolor(ix, iy, rgbToLPcolor(item 1 of rgb, item 2 of rgb, item 3 of rgb))
					end repeat
				end repeat
			end if
		end if
		
		
		# ------------ 'SESSION' PAD ON -------------
		if (item 1 of message = 176) and (item 2 of message = item 5 of ctrlButtons) and (item 3 of message > 0) then
			
			# start by lighting up the control buttons
			set session_pad to true
			set message to showControlButtons()
			
			# check if window position has changed
			findMaschineInstances()
			getMaschineInnerPosition()
			
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
		
		
		# ------------ 'SESSION' PAD OFF -------------
		if (item 1 of message = 176) and (item 2 of message = item 5 of ctrlButtons) and (item 3 of message is 0) then
			set session_pad to false
			set message to showControlButtons()
		end if
		
		
		# ------------ 'DRUMS' PAD ON -------------
		if (item 1 of message = 176) and (item 2 of message = item 6 of ctrlButtons) and (item 3 of message = 127) then
			set drums_pad to true
			set message to showControlButtons()
		end if
		
		
		# ------------ 'DRUMS' PAD OFF -------------
		if (item 1 of message = 176) and (item 2 of message = item 6 of ctrlButtons) and (item 3 of message = 0) then
			set drums_pad to false
			set message to showControlButtons()
		end if
		
		
		# ------------ 'KEYS' PAD ON -------------
		if (item 1 of message = 176) and (item 2 of message = item 7 of ctrlButtons) and (item 3 of message = 127) then
			if keys_pad is false then
				set keys_pad to true
			else
				set keys_pad to false
			end if
			set message to showControlButtons()
		end if
		
		
		# ------------ 'KEYS' PAD OFF -------------
		if (item 1 of message = 176) and (item 2 of message = item 7 of ctrlButtons) and (item 3 of message = 0) then
			set message to {} # ignore off message - the keys pad is a toggle button that toggles state on the midi on message
		end if
		
		
		# ------------ 'USER' PAD ON -------------
		if (item 1 of message = 176) and (item 2 of message = item 8 of ctrlButtons) and (item 3 of message = 127) then
			set user_pad to true
			set message to showControlButtons()
		end if
		
		
		# ------------ 'USER' PAD OFF -------------
		if (item 1 of message = 176) and (item 2 of message = item 8 of ctrlButtons) and (item 3 of message = 0) then
			set user_pad to false
			set message to showControlButtons()
		end if
		
		
		# ------------ NOTE ON -------------
		if (item 1 of message = 144) and (item 3 of message > 0) then
			set {padx, pady} to getLPpadXY(item 2 of message)
			set message to {}
			
			# get existing color in selected pad
			set oldLPcolor to item padx of item pady of mas_pattern_colors
			set oldIntensity to getLPintensity(oldLPcolor)
			
			# switch scenes if the keys pad is pressed 
			# but only do it if enogh time has elapsed - and if 'user' key is not pressed
			# also no need to switch if we clicked on a pattern that's already active
			# (i.e. only click if 'intensity' is not 'active')
			if keys_pad and user_pad is false and oldIntensity is not active then
				if sinceLastTime(true) > 500 then switchScene(0) # 500 milliseconds
			end if
			
			set is_new_pattern to clickMaschinePattern(padx, pady)
			
			# light up pad color for selected pattern
			if oldIntensity = inactive then
				set message to message & setLPcolor(padx, pady, setLPintensity(oldLPcolor, active))
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
		
		
		# ------------ SCENE KEYS -------------
		# when scene key is pressed, activate all patterns on that row
		if (item 1 of message = 176) and ((item 2 of message) mod 10 = 9) and (item 3 of message = 127) then
			set pady to 9 - ((item 2 of message) div 10)
			set message to {}
			
			if keys_pad then
				# use the switch scenes function if the keys pad is pressed
				if sinceLastTime(true) > 500 then switchScene(pady) # 500 milliseconds
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
		
	end if
end runme
