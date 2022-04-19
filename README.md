# LaunchPad for Maschine
A MidiPipe AppleScript that enables Maschine 2 users to use a LaunchPad Mini MK3 to control patterns in Maschine.
This enables a workflow familiar to those using LaunchPad to launch clips and scenes in Ableton Live, or those using Maschine Jam,
but without having to own either Ableton Live or Maschine Jam.

# Requirements
- Maschine 2 software (on a MacOS laptop)
- LaunchPad Mini MK3 (probably works with other LaunchPads from MK3 and MK2 series, but not confirmed)
- Cliclick (a free utility, [download here](https://github.com/BlueM/cliclick))
- MidiPipe (a free utility, [donwload here](http://www.subtlesoft.square7.net/MidiPipe.html))

You can use a Maschine MK3 or a different controller alongside this setup, but that's completely optional.

# Installation and setup

### 1. Install MidiPipe and Cliclick

Start by installing [MidiPipe](http://www.subtlesoft.square7.net/MidiPipe.html) and [Cliclick](https://github.com/BlueM/cliclick), 
following instructions on their websites. The expected location for cliclick when installed on your drive is in '/usr/local/bin/'

Note: I prefer using Cliclick version 3.3. rather than the latest one as it seems marginally faster when executing multiple clicks.

### 2. Connect your LaunchPad and switch it to 'programmer' mode

You can access the 'programmer' mode of your LaunchPad by holding the Session button (letters "LED" will appear), then press the bottom Scene Launch button
(the button at the very bottom right of your LaunchPad). The word "Programmer" should appear in big letters moving across the screen. Press the "Session" button again
and all the pads on your LaunchPad should go dark.

### 3. Set up a pipe in MidiPipe

1. Drag "MIDI in" into the pipe and select "LaunchPad Mini" as your input device
<img width="686" alt="Screenshot 2022-04-19 at 00 07 35" src="https://user-images.githubusercontent.com/5494990/163820063-e8424742-22e9-4fce-9d15-3cefc4e56982.png">

2. Repeat the same with "MIDI out" and select "LaunchPad Mini as your output device

3. Add "Applescript Trigger" from tools into the pipe, between "MIDI in" and "MIDI out"

4. Delete the script in "Applescript Trigger" and replace it with the [Launchpad for Maschine script](https://github.com/borisdivjak/LaunchPad-for-Maschine/blob/main/launchpad-for-maschine.applescript)
<img width="805" alt="Screenshot 2022-04-19 at 00 46 11" src="https://user-images.githubusercontent.com/5494990/163825363-c4b021c6-42e4-413c-a514-9e045cb36add.png">

5. Un-tick the "pass through" box below the script

6. Optional – rename the pipe and save it



### 4. Open Maschine 2 and make some music!

The script works well with the standalone app, but should also work when using Maschine as a plug-in in Logic Pro or Ableton Live. 
Additional hosts could be supported with minimal tweaks to the code.

# How to use it

In Maschine, make sure that you have the 'ideas' view open and that your list of patterns is clearly visible on the screen.
When using the plug-in version, swithch to 'medium' or 'large' view (in the Maschine plugin, select the dropdown and then View > Medium).
The script also assumes that the 'browser'/'library' is open in Maschine, although the script can easily be edited to change this
if you prefer using Maschine with the browser collapsed (try changing the property `firstx` to 32 in the script).

Make sure your LaunchPad is in "Programmer" mode – see instructions above.

### Press the "session" button to load the current Maschine patterns onto your LaunchPad

The 'session' button – the 5th button from the left in the top row – acts as a refresh button. When pressed, the script checks the current state of
the patterns in Maschine and recreates this view on the LaunchPad. It should automatically show the same layout and colours as the patterns in Maschine,
with the active patterns blinking white.

Whenever you make any changes in the software or using another controller, you should update the LaunchPad with the 'session' button.
 
### Activate patterns by pressing individual pattern pads

### Mute patterns / groups by pressing an empty pattern pad

### Activate all patterns in a row by pressing the 'scene selection' buttons 
The scene selection buttons are the ones in the right-most column on your LaunchPad. They are most likely labelled with right-pointing arrows.

### Create a new empty pattern by holding 'user' and pressing an empty pattern

### Sync pattern changes to your beat by holding the 'keys' button



# Using this script with other LaunchPads

Buttons are labelled differently
For Mk2 devices - not sure, but probably the top row uses different CC numbers

# Known issues and limitations

