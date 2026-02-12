import Foundation
import ImageIO

/// Calculates the total duration of one loop of a GIF file by summing frame delays.
/// Returns nil if the file is not a valid GIF or has no frame delay information.
func gifDuration(for url: URL) -> TimeInterval? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    let frameCount = CGImageSourceGetCount(source)
    guard frameCount > 1 else { return nil }
    
    var totalDuration: TimeInterval = 0
    
    for i in 0..<frameCount {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
              let gifDict = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            continue
        }
        
        // Prefer UnclampedDelayTime, fall back to DelayTime
        if let delay = gifDict[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double, delay > 0 {
            totalDuration += delay
        } else if let delay = gifDict[kCGImagePropertyGIFDelayTime as String] as? Double, delay > 0 {
            totalDuration += delay
        } else {
            // Default frame delay if none specified (common GIF convention: 100ms)
            totalDuration += 0.1
        }
    }
    
    return totalDuration > 0 ? totalDuration : nil
}
