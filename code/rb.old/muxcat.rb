#!/usr/bin/ruby

require 'pp'

class String
    def ascii!
        self.force_encoding("ascii-8bit")
    end
    def utf8!
        self.force_encoding("utf-8")
    end
end

NSM = "\xFF\xFE".ascii!  # next stream marker
NFM = "\xFF\xFD".ascii!  # next frame marker
NCM = "\xFF\xFC".ascii!  # next chunk marker

COLUMNSIZE=20
streams = []
streamwidths = []
frameno=0
streamno = 0
chunks = []

fname = ARGV.first
begin
    txt = File.open(fname).read.ascii!
rescue
    $STDERR.puts "Error: Can't open file #{fname}"
    exit 1
end

atxt = txt.bytes.clone
idx = 0
markers = []

# make a rough uneducated guess about the dimensions
# of the file, number of streams, number of chunks, 
# average line size, etc.

count_bytes    = txt.bytes.size
count_markers  = txt.bytes.count(0xff)
count_NSM      = txt.bytes.count(NSM.bytes.last)
count_NFM      = txt.bytes.count(NFM.bytes.last)
count_NCM      = txt.bytes.count(NCM.bytes.last)
count_NCM = 1 if count_NCM==0

guess_tagsize  = count_NSM*2 + count_NFM*2 + count_NCM*2
guess_frames   = (count_NFM*1.0) / (count_NCM*1.0)
guess_streams  = (count_NSM*1.0) / (guess_frames*1.0)
guess_datasize = count_bytes-guess_tagsize
guess_avglinsz = guess_datasize / guess_streams / count_NCM / guess_frames

=begin
puts "   count_bytes: #{count_bytes}"
puts " count_markers: #{count_markers}"
puts "     count_NSM: #{count_NSM}"
puts "     count_NFM: #{count_NFM}"
puts "     count_NCM: #{count_NCM}"
puts "  guess_frames: #{guess_frames}"
puts " guess_streams: #{guess_streams}"
puts "guess_avglinsz: #{guess_avglinsz}"
puts " guess_tagsize: #{guess_tagsize}"
puts "guess_datasize: #{guess_datasize}"
=end

begin
    markpos = atxt.index(0xff)
    break if markpos==nil 
    nextbyte=atxt[markpos+1]

    #puts "markpos: #{markpos} nextbyte: #{nextbyte}"
    case nextbyte
        when nil
            STDERR.puts "Error: Premature end of file at #{markpos}"
            exit 1

        when NSM.bytes.last # NSM 
            markers << [NSM.bytes.last, idx+markpos+1] 

        when NFM.bytes.last # NFM
            markers << [NFM.bytes.last, idx+markpos+1]

        when NCM.bytes.last # NCM
            markers << [NCM.bytes.last, idx+markpos+1]

        else
            STDERR.puts "Error: Invalid xtxt marker 0x#{nextbyte.to_s(16)} at #{markpos}"
            exit 1
    end
    #markerspos << idx+markpos 
    idx=markpos+idx+2
    atxt = atxt.slice(markpos+2,atxt.size)
end until atxt.size==0 


if markers.size==0 then
    markers << [-1, atxt.size+1]
end

idx=0

markers.each {|mark| 
    mtype  = mark.first
    mslice = mark.last
    aline  = txt.bytes[idx..mslice-2]
    #puts "mtype: #{mark}, #{mslice} idx: #{idx}, aline: #{aline}" 

    if aline.size==0 then
        aline = "".ascii!
    else
        aline = aline.pack("c*").ascii!
    end

    case mtype
        when -1 # plain text file, just one simple stream
            streams[0]=aline.split("\n")
            longest=0 
            streams[0].each {|line| 
                longest = line.bytes.size if line.bytes.size>longest 
            }
            streamwidths[0]=longest 
            break 

        when NSM.bytes.last
            streams[streamno]=[] if !streams[streamno]

            # convert text to utf8 encoding before
            # measuring string length
            uline = aline.clone.utf8!

            # discard BOM signature if present (EF BB BF)
            # only for the purpose of calculating column width
            # and displaying text on screen. The BOM is otherwise
            # preserved by muxt and demuxt
            if (uline.bytes[0..2] == [0xef, 0xbb, 0xbf])  then
                #the sliced copy of uchunk starts at the first utf-8 printable character
                uline=uline[1..-1] 
            end

            streams[streamno][frameno] = uline 
            
            if !streamwidths[streamno] then
                streamwidths[streamno] = uline.size 
            else
                if uline.size>streamwidths[streamno] then
                    streamwidths[streamno]=uline.size 
                end
            end 
            streamno=streamno+1
            idx=idx+2

        when NFM.bytes.last
            idx=idx+2
            streamno=0
            frameno=frameno+1

        else
            STDERR.puts "Invalid xtxt sequence at index #{idx}"
            exit 1
    end
    idx=idx+aline.bytes.size
}

streamlengths=[]
streams.each {|astream| streamlengths << astream.size }
longest_stream = streamlengths.max

# TO-DO: correct this in case we allow for 
# renumbering with command line options
linenochars = longest_stream.to_s.size  
linenochars = 3 if linenochars<3
linenochars = "%0#{linenochars}d"

0.upto(longest_stream-1) {|fno|
    line = ""
    0.upto(streams.size-1) {|streamidx|
        # TO-DO: make columnsize a command line option

        # COLUMNSIZE was used to make
        # all columns the same width
        # columnsize=COLUMNSIZE

        # make each column the width of the 
        # longest line for every column
        columnsize = streamwidths[streamidx]

        column = streams[streamidx][fno] ? streams[streamidx][fno] : ""
        column = column.chomp.utf8!     
        line << column.ljust(columnsize)[0..columnsize-1]
    }       

    # TO-DO: make line numbering a command line option
    puts "#{linenochars.%(fno+1)} #{line}"
}


=begin

# this is work in progress, preparing muxcat to take
# command line options to make it useful for some
# practical tasks.

opshortfmt = {
        :f => /^\-[a-z]\:[0-9]*\.[0-9]*/, # float
        :i => /^\-[a-z]\:*[0-9]/,         # integer
        :b => /^\-[a-z]/                 # boolean flag
}

oplongfmt = {
        :f => /^\-\-[a-z]\b:[0-9]*\.[0-9]*/, # float
        :i => /^\-\-[a-z]\:*[0-9]/,         # integer
        :b => [ /^\-\-*[a-z]/ ,  /^\-\-no\-*[a-z]/ ] # float
}


opts ={ # option type    long_format   mandatory description
        "h" => { :t=>:b, l: "head"    ,m: false, d: "Treat the first line as a header" },
        "l" => { :t=>:i, l: "line"    ,m: false, d: "Extract specified line"},
        "w" => { :t=>:w, l: "width"   ,m: false, d: "Specify column width"},
        "n" => { :t=>:b, l: "numbers" ,m: false, d: "Display line numbers"},
        "s" => { :t=>:i, l: "stream"  ,m: false, d: "Display specified stream only"}
}
=end
