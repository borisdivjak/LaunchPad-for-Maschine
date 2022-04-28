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
following instructions on their websites. 

Note: The expected location for cliclick when installed on your drive is in your **Applications folder**, so just copy it there. I also prefer using Cliclick version 3.3. rather than the latest one as it seems marginally faster when executing multiple clicks.

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

# First use (allowing the script to do what it needs)

Before you can use the script you'll need to allow it to access certain functions of your computer:
- MidiPipe needs access to 'system events'
- MidiPipe needs access to 'accessibility' controls
- MidiPipe needs access to 'screen recording' controls
- Cliclick needs to be allowed to run (as it's unsigned software)

The above permissions are needed so that the script can get access to your mouse (it moves the mouse around and performs click to activate patterns in Maschine) and to take screenshots of you Maschine patterns (so it knows which patterns are active). I realise all these warnings may seem daunting, but it's really nothing to be worried about.


1. Start Maschine and make sure it's in ideas view and make sure the LaunchPad is in 'programmer' mode
2. Press 'session' on the LaunchPad
3. A screen should pop-up asking access to 'system events' – click 'ok'
4. Next, a screen should pop-up requesting access to 'accessibility' features – click 'Open system preferences' and enable access for MidiPipe
5. Next, MidiPipe will request to record the screen – click 'Open system preferences' and enable access for MidiPipe
6. Press one of the pattern pads on the LaunchPad
7. A screen should pop-up saying the cliclick cannot be opened, as the developer is not verified
8. Open the 'System preferences' app and go to 'Security & Privacy > General'. There should be a note at the bottom saying 'cliclick was blocked from use ...' with a button 'Allow Anyway' next to it. Click the 'Allow Anyway' button
9. When you try using the LaunchPad again, another warning will pop-up about 'cliclick' – this time click 'Open'



# How to use it

In Maschine, make sure that you have the 'ideas' view open and that your list of patterns is clearly visible on the screen.
When using the plug-in version, switch to 'medium' or 'large' view (in the Maschine plugin, select the dropdown and then View > Medium).

Make sure your LaunchPad is in "Programmer" mode – see instructions above.

### Overview of the function buttons on the LaunchPad (only works in 'programmer' mode)

<img width="546" alt="Screenshot 2022-04-28 at 20 32 52" src="https://user-images.githubusercontent.com/5494990/165734059-8a55b3c2-f05b-4a3d-8722-8677ba795293.png">

Note that these buttons might have different names on LaunchPad X and LaunchPad Pro Mk3.

### Press the "session" button to load the current Maschine patterns onto your LaunchPad

The 'session' button – the 5th button from the left in the top row – acts as a refresh button. When pressed, the script checks the current state of
the patterns in Maschine and recreates this view on the LaunchPad. It should automatically show the same layout and colours as the patterns in Maschine,
with the active patterns blinking white.

Whenever you make any changes in the software or using another controller, you should update the LaunchPad with the 'session' button.
 
### Activate patterns by pressing individual pattern pads

### Mute patterns / groups by pressing an empty pattern pad

### Activate all patterns in a row by pressing the 'scene selection' buttons 
The scene selection buttons are the ones in the right-most column on your LaunchPad. They are most likely labelled with right-pointing arrows.

### Create a new empty pattern by holding 'drums' and pressing an empty pattern

### Sync pattern changes to your beat by toggling the 'keys' button
Press the keys button once to turn beat sync on (the button starts to blink) then again to turn it off. When in beat sync mode, the patterns will change according to the 'perform grid' setting in Maschine. You can change this setting to '1 bar' if you want your patterns to change at the end of a sigle bar, or 'scene' if you prefer them to change when the entire pattern/scene has played out.

### Enable MIDI change for Scenes in Maschine to update the LaunchPad with each scene change

When you change the scenes within the Maschine software or using your Maschine controller, it's possible to update the patterns on your LaunchPad with each scene change. To enable this, you need to enable 'MIDI change' for Scenes in your Maschine software.

1. In Maschine, go to 'Edit > MIDI change'
2. Under 'Scene' change trigger to 'MIDI note'
3. Leave 'Source' as 'None' and change channel to 10


# Using this script with other LaunchPads

I was only able to test this script with my LaunchPad Mini Mk3, so I can't guarantee that it will work with other devices. 

Having said that, it should work with LaunchPad X or LaucnhPad Pro MK3, provided you enable the 'programmer' mode on those devices (check the manual). Note that some buttons on these devices might be labeled differently to the ones on LP Mini Mk3.

It should be possible to modify the script to work with the Mk2 series of LaunchPads, but I don't have one and can't try this out. You'll probably have to change the assigned values for some the LaunchPad pads and buttons as these assignments have been changed in the Mk3 series.


# Known issues and limitations

- Only works on a Mac
- You'll need to make sure that the patterns are visible on your screen
- You need to keep Maschine (the software) in 'ideas' mode
- Only works up to 8 patterns in each of the first 8 instrument groups


# Diclaimer

This script is provided as is and I have no particular plans to keep it updated with future changes to Maschine and other related components. I also take no responsibility for any way you might use it, so proceed at your own discretion. I've developed this for my own personal use and I'm only sharing it here because I thought other people could probably benefit from it.
