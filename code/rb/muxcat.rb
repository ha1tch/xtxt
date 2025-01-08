#!/usr/bin/env ruby
require 'optparse'
require 'pp'

class String
  def ascii!
    self.force_encoding("ascii-8bit")
  end

  def utf8!
    self.force_encoding("utf-8")
  end
end

# Constants
NSM = "\xFF\xFE".ascii! # Next Stream Marker
NFM = "\xFF\xFD".ascii! # Next Frame Marker
NCM = "\xFF\xFC".ascii! # Next Chunk Marker

# Defaults
COLUMNSIZE = 20
opts = {
  show_line_numbers: true,
  stream_index: nil,
  column_width: COLUMNSIZE,
  treat_as_header: false,
  specific_line: nil
}

# Parse command line options
OptionParser.new do |parser|
  parser.banner = "Usage: muxcat.rb [options] <file>"

  parser.on("-n", "--numbers", "Display line numbers") do
    opts[:show_line_numbers] = true
  end

  parser.on("-sINDEX", "--stream INDEX", Integer, "Display only the specified stream index") do |index|
    opts[:stream_index] = index
  end

  parser.on("-wWIDTH", "--width WIDTH", Integer, "Specify column width") do |width|
    opts[:column_width] = width
  end

  parser.on("-h", "--head", "Treat the first line as a header") do
    opts[:treat_as_header] = true
  end

  parser.on("-lLINE", "--line LINE", Integer, "Display only the specified line") do |line|
    opts[:specific_line] = line
  end

  parser.on_tail("--help", "Show this message") do
    puts parser
    exit
  end
end.parse!

# Input file
fname = ARGV.first
if fname.nil?
  STDERR.puts "Error: No input file specified."
  exit 1
end

begin
  txt = File.open(fname).read.ascii!
rescue
  STDERR.puts "Error: Can't open file #{fname}"
  exit 1
end

# Parse markers
atxt = txt.bytes.clone
idx = 0
markers = []

begin
  markpos = atxt.index(0xFF)
  break if markpos.nil?
  nextbyte = atxt[markpos + 1]

  case nextbyte
  when NSM.bytes.last
    markers << [NSM.bytes.last, idx + markpos + 1]
  when NFM.bytes.last
    markers << [NFM.bytes.last, idx + markpos + 1]
  when NCM.bytes.last
    markers << [NCM.bytes.last, idx + markpos + 1]
  else
    STDERR.puts "Error: Invalid XTXT marker 0x#{nextbyte.to_s(16)} at #{markpos}"
    exit 1
  end
  idx = markpos + idx + 2
  atxt = atxt.slice(markpos + 2, atxt.size)
end until atxt.empty?

if markers.empty?
  markers << [-1, atxt.size + 1]
end

streams = []
streamwidths = []
frameno = 0
streamno = 0
idx = 0

markers.each do |mark|
  mtype = mark.first
  mslice = mark.last
  aline = txt.bytes[idx..mslice - 2]

  aline = aline.empty? ? "".ascii! : aline.pack("c*").ascii!

  case mtype
  when -1 # Plain text file, single stream
    streams[0] = aline.split("\n")
    longest = streams[0].map { |line| line.bytes.size }.max
    streamwidths[0] = longest
    break

  when NSM.bytes.last
    streams[streamno] ||= []
    uline = aline.clone.utf8!

    if uline.bytes[0..2] == [0xEF, 0xBB, 0xBF]
      uline = uline[1..-1] # Remove BOM
    end

    streams[streamno][frameno] = uline
    streamwidths[streamno] = [streamwidths[streamno].to_i, uline.size].max
    streamno += 1
    idx += 2

  when NFM.bytes.last
    idx += 2
    streamno = 0
    frameno += 1

  else
    STDERR.puts "Invalid XTXT sequence at index #{idx}"
    exit 1
  end
  idx += aline.bytes.size
end

# Output the streams
streamlengths = streams.map(&:size)
longest_stream = streamlengths.max
linenochars = [longest_stream.to_s.size, 3].max
linenofmt = "%0#{linenochars}d"

0.upto(longest_stream - 1) do |fno|
  next if opts[:specific_line] && fno + 1 != opts[:specific_line]

  line = ""
  0.upto(streams.size - 1) do |streamidx|
    next if opts[:stream_index] && streamidx != opts[:stream_index]

    columnsize = streamwidths[streamidx]
    column = streams[streamidx][fno] || ""
    column = column.chomp.utf8!
    line << column.ljust(columnsize)[0..columnsize - 1]
  end

  if opts[:show_line_numbers]
    puts "#{linenofmt % (fno + 1)} #{line}"
  else
    puts line
  end
end
