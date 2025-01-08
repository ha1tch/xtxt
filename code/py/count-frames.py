def count_frames_in_xtxt(file_path):
    """
    Counts the number of frames in an XTXT file by detecting the
    Next Frame Marker (NFM), defined as the sequence 0xFF 0xFD.

    :param file_path: Path to the .xtxt file
    :return: Number of frames detected
    """
    NFM = bytes([0xFF, 0xFD])  # Define the Next Frame Marker
    BUFFER_SIZE = 1024         # Process the file in 1 KB chunks

    try:
        frame_count = 0
        prev_byte = None

        with open(file_path, 'rb') as file:
            while chunk := file.read(BUFFER_SIZE):
                for i in range(len(chunk)):
                    current_byte = chunk[i]

                    # Check for boundary-spanning marker
                    if prev_byte == NFM[0] and current_byte == NFM[1]:
                        frame_count += 1

                    prev_byte = current_byte

        return frame_count

    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return -1
    except Exception as e:
        print(f"An error occurred: {e}")
        return -1

if __name__ == "__main__":
    # Specify the path to the .xtxt file
    file_path = "input.xtxt"

    # Count the frames and print the result
    frames = count_frames_in_xtxt(file_path)
    if frames >= 0:
        print(f"Total frames: {frames}")
