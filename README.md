# SwiftyPlayer

SwiftyPlayer is an audio and video playback component written in Swift, based on [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer). SwiftyPlayer only focuses on playback events, and does not provide screen rotation, gesture control, and other functions that are not related to playback events.

## Features

- [x] Only focus on audio and video playback events
- [x] Complete basic properties of the player
    - [x] Player status management, playing/paused/buffering and other basic player attributes
    - [x] Play, pause, fast forward and rewind, previous song, next song, etc.
    - [x] Provides a repeat mode for resource playback
- [x] Provide complete customization options, such as
    - [x] Enable options for playing videos in the background
    - [x] Provide Buffer strategy options
- [x] Switch resource quality according to network environment
- [x] Provides the analysis method of SRT file format

## Requirements

 * iOS 10+
 * Swift 5.1+

## TODO

- [ ] Add Example project

## Wiki

You can view information about how to install and how to use through the [wiki](https://github.com/shiwei93/SwiftyPlayer/wiki).

 * [Installation Guide](https://github.com/shiwei93/SwiftyPlayer/wiki/Installation-Guide) - Install SwiftyPlayer into your project.
 * [Cheat Sheet](https://github.com/shiwei93/SwiftyPlayer/wiki/Cheat-Sheet) - See this page for useful code snippets

## License

SwiftyPlayer is released under the MIT license. See LICENSE for details.