# Vidio

A simple Swift package for playing local video files in iOS applications. Built with SwiftUI and AVFoundation.

## Requirements

- iOS 13.0+
- Swift 6.1+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/adamkaump/vidio.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Go to File > Add Packages...
2. Enter the repository URL: `https://github.com/adamkaump/vidio.git`
3. Click Add Package

## Usage

### SwiftUI View

The simplest way to use Vidio is with the SwiftUI view:

```swift
import SwiftUI
import vidio

struct ContentView: View {
    var body: some View {
        VideoPlayer(url: URL(fileURLWithPath: "/path/to/your/video.mp4"))
    }
}
```

### Programmatic Control

For more control over video playback, use the `VideoPlayerController`:

```swift
import vidio

// Create a controller
let controller = VideoPlayerController(url: videoURL)

// Control playback
await controller.play()
await controller.pause()
await controller.seek(to: 30.0) // Seek to 30 seconds

// Get playback information
let currentTime = controller.currentTime
let duration = controller.duration
```

Note: Since `VideoPlayerController` is marked with `@MainActor`, you'll need to use `await` when calling its methods from a non-main context.

## API Reference

### VideoPlayer

A SwiftUI view that displays a video player.

```swift
public struct VideoPlayer: View {
    public init(url: URL)
}
```

### VideoPlayerController

A class that provides programmatic control over video playback.

```swift
@MainActor
public class VideoPlayerController {
    public init(url: URL)
    
    public func play()
    public func pause()
    public func seek(to time: Double)
    public var currentTime: Double
    public var duration: Double
}
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 