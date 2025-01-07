def count_frames_in_xtxt(file_path):
    """
    Counts the number of frames in an XTXT file by detecting the
    Next Frame Marker (NFM), defined as the sequence 0xFF 0xFD.
    
    :param file_path: Path to the .xtxt file
    :return: Number of frames detected
    """
    NFM = bytes([0xFF, 0xFD])  # Define the Next Frame Marker

    try:
        with open(file_path, 'rb') as file:
            data = file.read()  # Read the entire file into memory

        frame_count = 0
        i = 0
        while i < len(data) - 1:
            if data[i] == NFM[0] and data[i + 1] == NFM[1]:
                frame_count += 1
                i += 2  # Skip the marker
            else:
                i += 1

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
