import Foundation
import AVFoundation
import SwiftUI
import FFmpeg

/// A SwiftUI view that can play local video files
public struct VideoPlayer: View {
    private let player: AVPlayer
    private let playerLayer: AVPlayerLayer
    private let videoURL: URL
    
    public init(url: URL) {
        print("Initializing VideoPlayer with URL: \(url)")
        self.videoURL = url
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Error: Video file does not exist at path: \(url.path)")
            fatalError("Video file not found")
        }
        
        // Create asset and check if it's playable
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Add observer for item status
        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: playerItem, queue: .main) { notification in
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("❌ Error playing video: \(error.localizedDescription)")
            }
        }
        
        // Add observer for item status changes
        NotificationCenter.default.addObserver(forName: .AVPlayerItemNewErrorLogEntry, object: playerItem, queue: .main) { notification in
            if let errorLog = playerItem.errorLog() {
                print("❌ Error log: \(errorLog)")
            }
        }
        
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        self.playerLayer = AVPlayerLayer(player: player)
        self.playerLayer.videoGravity = .resizeAspect
        
        // Check if the asset is playable
        Task {
            do {
                let isPlayable = try await asset.load(.isPlayable)
                print("✅ Asset is playable: \(isPlayable)")
                
                if !isPlayable {
                    // If not playable, try to convert using FFmpeg
                    await convertVideoIfNeeded()
                }
                
                if let duration = try? await asset.load(.duration) {
                    print("✅ Video duration: \(duration.seconds) seconds")
                }
                
                // Check available tracks
                await MainActor.run {
                    let videoTracks = asset.tracks(withMediaType: .video)
                    for track in videoTracks {
                        print("✅ Found video track with format: \(track.formatDescriptions)")
                    }
                    
                    let audioTracks = asset.tracks(withMediaType: .audio)
                    for track in audioTracks {
                        print("✅ Found audio track with format: \(track.formatDescriptions)")
                    }
                }
            } catch {
                print("❌ Error checking asset playability: \(error.localizedDescription)")
                // Try to convert using FFmpeg
                await convertVideoIfNeeded()
            }
        }
    }
    
    private func convertVideoIfNeeded() async {
        print("Attempting to convert video using FFmpeg")
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        // FFmpeg command to convert to H.264 MP4
        let command = "-i \(videoURL.path) -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k \(tempURL.path)"
        
        do {
            let rc = try await Task.detached {
                return FFmpeg.execute(command)
            }.value
            
            if rc == 0 {
                print("✅ Video conversion successful")
                // Update player with converted video
                await MainActor.run {
                    let asset = AVAsset(url: tempURL)
                    let playerItem = AVPlayerItem(asset: asset)
                    player.replaceCurrentItem(with: playerItem)
                }
            } else {
                print("❌ Video conversion failed with return code: \(rc)")
            }
        } catch {
            print("❌ Error during video conversion: \(error.localizedDescription)")
        }
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
    private let ffmpegContext: FFmpegContext?
    
    public init(url: URL) {
        print("Initializing VideoPlayerController with URL: \(url)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ Error: Video file does not exist at path: \(url.path)")
            fatalError("Video file not found")
        }
        
        // Try to create FFmpeg context first
        var context: FFmpegContext?
        do {
            context = try FFmpegContext(url: url)
            print("✅ Successfully created FFmpeg context")
        } catch {
            print("❌ Failed to create FFmpeg context: \(error.localizedDescription)")
        }
        self.ffmpegContext = context
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)
        
        // Check if the asset is playable
        Task {
            do {
                let isPlayable = try await asset.load(.isPlayable)
                print("✅ Asset is playable: \(isPlayable)")
                
                if let duration = try? await asset.load(.duration) {
                    print("✅ Video duration: \(duration.seconds) seconds")
                }
                
                // Check available tracks
                await MainActor.run {
                    let videoTracks = asset.tracks(withMediaType: .video)
                    for track in videoTracks {
                        print("✅ Found video track with format: \(track.formatDescriptions)")
                    }
                    
                    let audioTracks = asset.tracks(withMediaType: .audio)
                    for track in audioTracks {
                        print("✅ Found audio track with format: \(track.formatDescriptions)")
                    }
                }
            } catch {
                print("❌ Error checking asset playability: \(error.localizedDescription)")
            }
        }
    }
    
    /// Play the video
    public func play() {
        print("Playing video")
        if ffmpegContext != nil {
            // Use FFmpeg for playback
            print("Using FFmpeg for playback")
            // TODO: Implement FFmpeg playback
        } else {
            // Use native AVPlayer
            player.play()
        }
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