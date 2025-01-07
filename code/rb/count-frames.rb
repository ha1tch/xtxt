def count_frames_in_xtxt(file_path)
  marker_high = 0xFF
  marker_low = 0xFD
  frame_count = 0

  begin
    File.open(file_path, 'rb') do |file|
      previous_byte = nil

      file.each_byte do |current_byte|
        if previous_byte == marker_high && current_byte == marker_low
          frame_count += 1
        end
        previous_byte = current_byte
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
