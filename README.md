# LinuxSplit

A timer application like LiveSplit, designed to be platform-agnostic. Uses the Godot Engine.

## Usage

This app is aimed to function much like LiveSplit, with functionality essentially being the same. That being said, not all features are expected to work initially and some of them are limited by restrictions of both the OS and the engine we use to do the grunt work for us (Godot). If a feature does not yet exist, please make an issue with it and I will see if it is possible.

These missing features include:
- Global hotkeys: Godot is built in such a way as that inputs are only read when the window is in focus. Implementing this is possible, but it would either require a fork of Godot that has these options or require some other workarounds with GDExtension. Given how important it is for this to work, this feature is a priority once the minimum viable product has been created. This option is flat-out not available to my knowledge on Wayland.
- SpeedRunsLive integration: I haven't looked into it much and don't really care for it as a feature. Implementation will be done if desired.
- Modding/Module support: Modding is a high priority but ultimately not a core feature. Once everything else is working, I'll add it.