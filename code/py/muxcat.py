import argparse
import os

# Constants
NSM = b"\xFF\xFE"  # Next Stream Marker
NFM = b"\xFF\xFD"  # Next Frame Marker
NCM = b"\xFF\xFC"  # Next Chunk Marker
COLUMNSIZE = 20

# Argument Parser
parser = argparse.ArgumentParser(description="Parse and display XTXT file streams.")
parser.add_argument("file", help="The XTXT file to process.")
parser.add_argument("-n", "--numbers", action="store_true", help="Display line numbers.")
parser.add_argument("-s", "--stream", type=int, help="Display only the specified stream index.")
parser.add_argument("-w", "--width", type=int, default=COLUMNSIZE, help="Specify column width.")
parser.add_argument("-H", "--head", action="store_true", help="Treat the first line as a header.")
parser.add_argument("-l", "--line", type=int, help="Display only the specified line.")
args = parser.parse_args()

# File Reading
if not os.path.isfile(args.file):
    print(f"Error: File '{args.file}' not found.")
    exit(1)

with open(args.file, "rb") as f:
    txt = f.read()

# Parse Markers
atxt = bytearray(txt)
idx = 0
markers = []

while idx < len(atxt):
    try:
        markpos = atxt.index(0xFF, idx)
        nextbyte = atxt[markpos + 1]

        if nextbyte == NSM[1]:
            markers.append((NSM[1], markpos))
        elif nextbyte == NFM[1]:
            markers.append((NFM[1], markpos))
        elif nextbyte == NCM[1]:
            markers.append((NCM[1], markpos))
        else:
            print(f"Error: Invalid marker at position {markpos}: 0x{nextbyte:02X}")
            exit(1)

        idx = markpos + 2
    except ValueError:
        break

streams = []
stream_widths = []
frame_no = 0
stream_no = 0
idx = 0

# Process Markers
for mtype, mpos in markers:
    aline = atxt[idx:mpos]
    idx = mpos + 2

    if mtype == NSM[1]:
        while len(streams) <= stream_no:
            streams.append([])
            stream_widths.append(0)

        line = aline.decode("utf-8", errors="replace").rstrip()
        streams[stream_no].append(line)
        stream_widths[stream_no] = max(stream_widths[stream_no], len(line))
        stream_no += 1

    elif mtype == NFM[1]:
        stream_no = 0
        frame_no += 1

# Calculate Line Numbers and Widths
longest_stream = max(len(s) for s in streams)
line_no_width = len(str(longest_stream))
line_no_fmt = f"%0{line_no_width}d "

# Output
for line_no in range(longest_stream):
    if args.line and line_no + 1 != args.line:
        continue

    line = ""
    for stream_idx, stream in enumerate(streams):
        if args.stream is not None and stream_idx != args.stream:
            continue

        col_width = args.width or stream_widths[stream_idx]
        content = stream[line_no] if line_no < len(stream) else ""
        line += content.ljust(col_width)

    if args.numbers:
        print(f"{line_no_fmt % (line_no + 1)}{line}")
    else:
        print(line)
