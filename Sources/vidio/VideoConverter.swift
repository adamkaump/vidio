import Foundation
import FFmpegKit

public class VideoConverter {
    
    public enum VideoConverterError: Error {
        case conversionFailed(String)
        case invalidInput
        case streamingError(String)
    }
    
    public static func convertToMP4(inputURL: URL, outputURL: URL) async throws {
        // Ensure the input file exists
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw VideoConverterError.invalidInput
        }
        
        // Create output directory if it doesn't exist
        let outputDirectory = outputURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        
        // Build FFmpeg command
        let command = "-i \(inputURL.path) -c:v libx264 -c:a aac -movflags +faststart \(outputURL.path)"
        
        // Execute FFmpeg command
        let session = try await withCheckedThrowingContinuation { continuation in
            FFmpegKit.executeAsync(command) { session in
                if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                    continuation.resume()
                } else {
                    let logs = session?.getLogsAsString() ?? "Unknown error"
                    continuation.resume(throwing: VideoConverterError.conversionFailed(logs))
                }
            }
        }
        
        // Verify the output file exists
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw VideoConverterError.conversionFailed("Output file was not created")
        }
    }
    
    public static func getVideoInfo(inputURL: URL) async throws -> [String: String] {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw VideoConverterError.invalidInput
        }
        
        let command = "-i \(inputURL.path)"
        
        return try await withCheckedThrowingContinuation { continuation in
            FFmpegKit.executeAsync(command) { session in
                if let logs = session?.getLogsAsString() {
                    // Parse the logs to extract video information
                    var info: [String: String] = [:]
                    
                    // Extract duration
                    if let durationMatch = logs.range(of: "Duration: ([0-9:.]+)", options: .regularExpression) {
                        let duration = String(logs[durationMatch])
                        info["duration"] = duration
                    }
                    
                    // Extract video stream info
                    if let videoMatch = logs.range(of: "Stream #0:0.*Video: ([^,]+)", options: .regularExpression) {
                        let videoInfo = String(logs[videoMatch])
                        info["videoCodec"] = videoInfo
                    }
                    
                    continuation.resume(returning: info)
                } else {
                    continuation.resume(throwing: VideoConverterError.conversionFailed("Failed to get video info"))
                }
            }
        }
    }
    
    public static func startStreamingConversion(inputURL: URL, outputDirectory: URL, segmentDuration: Int = 4) async throws -> URL {
        // Ensure the input file exists
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw VideoConverterError.invalidInput
        }
        
        // Create output directory if it doesn't exist
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        
        // Create a manifest file path
        let manifestURL = outputDirectory.appendingPathComponent("manifest.m3u8")
        
        // Build FFmpeg command for HLS streaming
        let command = "-i \(inputURL.path) -c:v libx264 -c:a aac -f hls -hls_time \(segmentDuration) -hls_list_size 0 -hls_segment_filename \(outputDirectory.path)/segment_%03d.ts \(manifestURL.path)"
        
        // Execute FFmpeg command
        let session = try await withCheckedThrowingContinuation { continuation in
            FFmpegKit.executeAsync(command) { session in
                if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                    continuation.resume()
                } else {
                    let logs = session?.getLogsAsString() ?? "Unknown error"
                    continuation.resume(throwing: VideoConverterError.conversionFailed(logs))
                }
            }
        }
        
        // Verify the manifest file exists
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw VideoConverterError.conversionFailed("Manifest file was not created")
        }
        
        return manifestURL
    }
    
    public static func createStreamingMP4(inputURL: URL, outputURL: URL, segmentDuration: Int = 4) async throws -> URL {
        // Ensure the input file exists
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw VideoConverterError.invalidInput
        }
        
        // Create output directory if it doesn't exist
        let outputDirectory = outputURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        
        // Build FFmpeg command for fragmented MP4
        let command = "-i \(inputURL.path) -c:v libx264 -c:a aac -movflags +frag_keyframe+empty_moov+default_base_moof -f mp4 -segment_time \(segmentDuration) -reset_timestamps 1 \(outputURL.path)"
        
        // Execute FFmpeg command
        let session = try await withCheckedThrowingContinuation { continuation in
            FFmpegKit.executeAsync(command) { session in
                if let returnCode = session?.getReturnCode(), returnCode.isValueSuccess() {
                    continuation.resume()
                } else {
                    let logs = session?.getLogsAsString() ?? "Unknown error"
                    continuation.resume(throwing: VideoConverterError.conversionFailed(logs))
                }
            }
        }
        
        // Verify the output file exists
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw VideoConverterError.conversionFailed("Output file was not created")
        }
        
        return outputURL
    }
    
    public static func monitorStreamingProgress(inputURL: URL) async throws -> AsyncStream<Double> {
        return AsyncStream { continuation in
            let command = "-i \(inputURL.path) -f null -"
            
            FFmpegKit.executeAsync(command) { session in
                if let logs = session?.getLogsAsString() {
                    // Parse progress from logs
                    let progressPattern = "time=([0-9:.]+)"
                    if let regex = try? NSRegularExpression(pattern: progressPattern, options: []) {
                        let nsString = logs as NSString
                        let matches = regex.matches(in: logs, options: [], range: NSRange(location: 0, length: nsString.length))
                        
                        for match in matches {
                            let timeString = nsString.substring(with: match.range(at: 1))
                            if let time = Double(timeString) {
                                continuation.yield(time)
                            }
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
} 