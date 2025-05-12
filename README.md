# Vidio

A simple Swift package for playing local video files in iOS applications. Built with SwiftUI and AVFoundation.

## Requirements

- iOS 15.0+
- Swift 6.1+

## Supported Formats

The package supports all video formats that AVFoundation can play, including:
- MP4 (.mp4)
- MOV (.mov)
- AVI (.avi)
- M4V (.m4v)
- 3GP (.3gp)
- And other formats supported by iOS

Note: The actual support for specific formats depends on the codecs used in the video file. The package will log detailed information about the video tracks and any playback errors to help diagnose compatibility issues.

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

### Loading Local Video Files

There are several ways to load local video files:

1. From your app's bundle:
```swift
// Make sure to add the video file to your Xcode project
// and check "Copy items if needed" in the file inspector
if let videoURL = Bundle.main.url(forResource: "your_video", withExtension: "mp4") {
    VideoPlayer(url: videoURL)
}
```

2. From the Documents directory:
```swift
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let videoURL = documentsPath.appendingPathComponent("your_video.mp4")
VideoPlayer(url: videoURL)
```

3. From a specific file path:
```swift
let videoURL = URL(fileURLWithPath: "/path/to/your/video.mp4")
VideoPlayer(url: videoURL)
```

### SwiftUI View

The simplest way to use Vidio is with the SwiftUI view:

```swift
import SwiftUI
import vidio

struct ContentView: View {
    var body: some View {
        // Example using a video from the app bundle
        if let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mp4") {
            VideoPlayer(url: videoURL)
                .frame(width: 300, height: 200)
        } else {
            Text("Video file not found")
        }
    }
}
```

### Programmatic Control

For more control over video playback, use the `VideoPlayerController`:

```swift
import vidio

// Create a controller with a video from the app bundle
if let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mp4") {
    let controller = VideoPlayerController(url: videoURL)
    
    // Control playback
    await controller.play()
    await controller.pause()
    await controller.seek(to: 30.0) // Seek to 30 seconds
    
    // Get playback information
    let currentTime = controller.currentTime
    let duration = controller.duration
}
```

Note: Since `VideoPlayerController` is marked with `@MainActor`, you'll need to use `await` when calling its methods from a non-main context.

## Debugging

The package includes detailed logging to help diagnose playback issues:
- File existence checks
- Asset playability verification
- Video and audio track format information
- Playback error logging

Check the console output for detailed information about the video file and any potential issues.

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