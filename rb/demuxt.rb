#!/usr/bin/ruby
require 'pp'

NSM = "\xFF\xFE"  # next stream marker
NFM = "\xFF\xFD"  # next frame marker
NCM = "\xFF\xFC"  # next chunk marker

fname = ARGV.first
txt = File.open(fname).read
txt.force_encoding("ascii-8bit")
COLUMNSIZE=20
streams = []
streamwidths = []
idx = 0
frameno=0
chunkno = 0

begin
    chunk=""
    chunk.force_encoding("ascii-8bit")
    cb = txt.bytes[idx]
    
    until (cb == 0xff)  
        chunk = chunk + (cb.chr)
        #puts "cb #{cb} #{cb.class} - idx #{idx.class} #{idx} - chunk #{chunk.class} \"#{chunk}\""
        idx=idx+1   
        cb = txt.bytes[idx]
    end 

    nextbyte = txt.bytes[idx+1]

    case nextbyte
        when NSM.bytes.last 
            #puts "NSM found at #{idx}"
            streams[chunkno]=[] if !streams[chunkno]
            streams[chunkno][frameno] = chunk 
            if !streamwidths[chunkno] then
                streamwidths[chunkno] = chunk.size  
            else
                if chunk.size>streamwidths[chunkno] then
                    streamwidths[chunkno]=chunk.size 
                end
            end 
            chunkno=chunkno+1
            idx=idx+2

        when NFM.bytes.last
            #puts "NFM found at #{idx}"
            idx=idx+2
            chunkno=0
            frameno=frameno+1
        else
            throw "Invalid xtxt sequence at index #{idx}"
    end
end until idx>=txt.size-1 


streamlengths=[]
streams.each {|astream| streamlengths << astream.size }
longest_stream = streamlengths.max

#pp streams
#pp  stream_sizes
#puts "longest stream: #{longest_stream} "

fnamenoext = File.basename(fname).rpartition(".").first
outdir = "#{fnamenoext}.demuxed"
Dir.mkdir(outdir)

streamdigits=2
streamdigits = (streams.size-1).to_s.size if (streams.size-1).to_s.size > streamdigits 
indexformat = "%0#{streamdigits}d"

streams.each_with_index {|stream,index|
    outfname = "#{outdir}#{File::Separator}#{fnamenoext}.s#{indexformat.%(index)}.txt"
    outfile = File.open(outfname, File::CREAT|File::TRUNC|File::RDWR, 0640)
    outfile.write(stream.join)
    outfile.close 
}
puts "#{streams.size} streams demuxed into #{outdir}"
