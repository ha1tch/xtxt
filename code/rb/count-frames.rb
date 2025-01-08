def count_frames_in_xtxt(file_path)
  marker_high = 0xFF
  marker_low = 0xFD
  frame_count = 0
  buffer_size = 1024 # Define buffer size
  previous_byte = nil

  begin
    File.open(file_path, 'rb') do |file|
      buffer = ''.b # Initialize an empty binary buffer

      while (bytes_read = file.read(buffer_size, buffer))
        bytes = buffer.bytes
        buffer_length = bytes.length

        # Check for boundary marker spanning chunks
        if previous_byte == marker_high && bytes.first == marker_low
          frame_count += 1
        end

        # Iterate through the buffer
        (0...buffer_length - 1).each do |i|
          if bytes[i] == marker_high && bytes[i + 1] == marker_low
            frame_count += 1
          end
        end

        # Store the last byte of the buffer for the next iteration
        previous_byte = bytes.last
      end
    end

    frame_count
  rescue Errno::ENOENT
    puts "Error: File '#{file_path}' not found."
    -1
  rescue IOError => e
    puts "An error occurred while reading the file: #{e.message}"
    -1
  end
end

if __FILE__ == $0
  file_path = 'input.xtxt'
  frame_count = count_frames_in_xtxt(file_path)

  if frame_count >= 0
    puts "Total frames: #{frame_count}"
  else
    puts "Failed to count frames."
  end
end
