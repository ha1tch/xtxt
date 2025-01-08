import Foundation

func countFramesInXtxt(filePath: String) -> Int? {
    let markerHigh: UInt8 = 0xFF
    let markerLow: UInt8 = 0xFD
    let bufferSize = 1024
    var frameCount = 0
    var previousByte: UInt8? = nil

    do {
        let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: filePath))

        while true {
            let buffer = fileHandle.readData(ofLength: bufferSize)
            if buffer.isEmpty {
                break
            }

            let bytes = [UInt8](buffer)

            // Check for boundary marker spanning chunks
            if let prev = previousByte, !bytes.isEmpty, prev == markerHigh && bytes[0] == markerLow {
                frameCount += 1
            }

            // Process the current buffer
            for i in 0..<(bytes.count - 1) {
                if bytes[i] == markerHigh && bytes[i + 1] == markerLow {
                    frameCount += 1
                }
            }

            // Store the last byte for boundary check
            previousByte = bytes.last
        }

        fileHandle.closeFile()
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
