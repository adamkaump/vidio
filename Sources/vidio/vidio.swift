import Foundation
import AVFoundation
import SwiftUI

/// A SwiftUI view that can play local video files
public struct VideoPlayer: View {
    private let player: AVPlayer
    private let playerLayer: AVPlayerLayer
    
    public init(url: URL) {
        print("Initializing VideoPlayer with URL: \(url)")
        let player = AVPlayer(url: url)
        self.player = player
        self.playerLayer = AVPlayerLayer(player: player)
    }
    
    public var body: some View {
        VideoPlayerRepresentable(player: player, playerLayer: playerLayer)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                print("VideoPlayer appeared")
                player.play()
            }
            .onDisappear {
                print("VideoPlayer disappeared")
                player.pause()
            }
    }
}

/// A UIViewRepresentable that wraps AVPlayerLayer for SwiftUI
private struct VideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    let playerLayer: AVPlayerLayer
    
    func makeUIView(context: Context) -> UIView {
        print("Creating UIView for VideoPlayer")
        let view = PlayerView(playerLayer: playerLayer)
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("Updating UIView frame: \(uiView.bounds)")
    }
}

/// A UIView subclass that properly handles AVPlayerLayer layout
private class PlayerView: UIView {
    private let playerLayer: AVPlayerLayer
    
    init(playerLayer: AVPlayerLayer) {
        self.playerLayer = playerLayer
        super.init(frame: .zero)
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("PlayerView layoutSubviews: \(bounds)")
        playerLayer.frame = bounds
    }
}

/// A class to manage video playback
@MainActor
public class VideoPlayerController {
    private let player: AVPlayer
    
    public init(url: URL) {
        print("Initializing VideoPlayerController with URL: \(url)")
        self.player = AVPlayer(url: url)
    }
    
    /// Play the video
    public func play() {
        print("Playing video")
        player.play()
    }
    
    /// Pause the video
    public func pause() {
        print("Pausing video")
        player.pause()
    }
    
    /// Seek to a specific time in the video
    /// - Parameter time: The time to seek to in seconds
    public func seek(to time: Double) {
        print("Seeking to time: \(time)")
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime)
    }
    
    /// Get the current playback time in seconds
    public var currentTime: Double {
        return player.currentTime().seconds
    }
    
    /// Get the total duration of the video in seconds
    public var duration: Double {
        return player.currentItem?.duration.seconds ?? 0
    }
} 