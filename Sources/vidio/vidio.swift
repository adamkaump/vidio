import Foundation
import AVFoundation
import SwiftUI

/// A SwiftUI view that can play local video files
public struct VideoPlayer: View {
    private let player: AVPlayer
    private let playerLayer: AVPlayerLayer
    
    public init(url: URL) {
        let player = AVPlayer(url: url)
        self.player = player
        self.playerLayer = AVPlayerLayer(player: player)
    }
    
    public var body: some View {
        VideoPlayerRepresentable(player: player, playerLayer: playerLayer)
    }
}

/// A UIViewRepresentable that wraps AVPlayerLayer for SwiftUI
private struct VideoPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    let playerLayer: AVPlayerLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        playerLayer.frame = uiView.bounds
    }
}

/// A class to manage video playback
public class VideoPlayerController {
    private let player: AVPlayer
    
    public init(url: URL) {
        self.player = AVPlayer(url: url)
    }
    
    /// Play the video
    public func play() {
        player.play()
    }
    
    /// Pause the video
    public func pause() {
        player.pause()
    }
    
    /// Seek to a specific time in the video
    /// - Parameter time: The time to seek to in seconds
    public func seek(to time: Double) {
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