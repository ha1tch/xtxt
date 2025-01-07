import Foundation

func countFramesInXtxt(filePath: String) -> Int? {
    let markerHigh: UInt8 = 0xFF
    let markerLow: UInt8 = 0xFD
    var frameCount = 0
    var previousByte: UInt8? = nil

    do {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))

        for byte in fileData {
            if let prev = previousByte, prev == markerHigh && byte == markerLow {
                frameCount += 1
            }
            previousByte = byte
        }

        return frameCount
    } catch {
        print("Error: Could not read file at \(filePath). \(error.localizedDescription)")
        return nil
    }
}

// Main execution
if CommandLine.arguments.count > 1 {
    let filePath = CommandLine.arguments[1]

    if let frameCount = countFramesInXtxt(filePath: filePath) {
        print("Total frames: \(frameCount)")
    } else {
        print("Failed to count frames.")
    }
} else {
    print("Usage: xtxt_frame_counter <file_path>")
}
